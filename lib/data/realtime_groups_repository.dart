import 'dart:async';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';

import '../models/json.dart';
import '../models/user.dart';
import 'groups_repository.dart';

/// Realtime Database, written as:
///
/// ```text
/// groups/{gid}        { name, code, ownerId, kind, createdAt, activeSession,
///                       members: { uid: true } }
/// userGroups/{uid}    { gid: true }      // the groups this member is in
/// inviteCodes/{CODE}  gid                // so a code can be found
/// publicProfiles/{uid} { name }          // read to fill in member names
/// users/{uid}         { name, email }    // private: only its owner reads it
/// ```
///
/// Four of those are Realtime Database specific and worth knowing about:
///
/// * `publicProfiles` carries the name a group card shows. It cannot be
///   `users`: reading one profile is allowed, but reading the whole `users`
///   node is a different question, and the rules say no, because it would hand
///   every signed in person every email address in the app.
/// * `inviteCodes` exists because the database cannot search for a record by a
///   string value. It is a second copy of "this code means this group", written
///   alongside the group, and the rules keep it to one field so nobody can
///   repoint somebody else's group by guessing a code.
/// * `userGroups` is the list `loadGroups` walks. The obvious alternative,
///   querying `groups` by `members/{uid}`, cannot work: the rules let a member
///   read their own group, and the database grants a query only when the whole
///   queried path can be read, which would mean every group in the app.
/// * So joining writes two places, the membership and this index, and the rules
///   only allow the index entry for a group the writer is already in.
class RealtimeGroupsRepository implements LgtmGroupsRepository {
  RealtimeGroupsRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  @override
  Future<List<LgtmGroup>> loadGroups({required LgtmMember member}) async {
    try {
      final groups = await _readGroupsFor(member);
      return groups;
    } catch (failure) {
      throw LgtmGroupsException.forFailure(failure);
    }
  }

  @override
  Stream<List<LgtmGroup>> watchGroups({required LgtmMember member}) {
    late final StreamController<List<LgtmGroup>> controller;
    StreamSubscription<DatabaseEvent>? indexSubscription;
    StreamSubscription<DatabaseEvent>? profileSubscription;
    final groupSubscriptions = <String, StreamSubscription<DatabaseEvent>>{};
    var refreshVersion = 0;

    Future<void> refresh() async {
      final version = ++refreshVersion;
      try {
        final groups = await _readGroupsFor(member);
        if (!controller.isClosed && version == refreshVersion) {
          controller.add(groups);
        }
      } catch (failure) {
        if (!controller.isClosed && version == refreshVersion) {
          controller.addError(LgtmGroupsException.forFailure(failure));
        }
      }
    }

    void watchIndexedGroups(DataSnapshot snapshot) {
      final ids = {
        for (final entry in jsonAsMap(snapshot.value).entries)
          if (entry.value == true) entry.key,
      };
      for (final id in groupSubscriptions.keys.toList()) {
        if (!ids.contains(id)) {
          unawaited(groupSubscriptions.remove(id)?.cancel());
        }
      }
      for (final id in ids) {
        groupSubscriptions.putIfAbsent(id, () {
          return _database.ref('groups/$id').onValue.listen(
            (_) => unawaited(refresh()),
            onError: (Object failure) => controller.addError(
              LgtmGroupsException.forFailure(failure),
            ),
          );
        });
      }
      unawaited(refresh());
    }

    controller = StreamController<List<LgtmGroup>>(
      onListen: () {
        indexSubscription = _database
            .ref('userGroups/${member.id}')
            .onValue
            .listen(
              (event) => watchIndexedGroups(event.snapshot),
              onError: (Object failure) => controller.addError(
                LgtmGroupsException.forFailure(failure),
              ),
            );
        profileSubscription = _database.ref('publicProfiles').onValue.listen(
          (_) => unawaited(refresh()),
          onError: (Object failure) => controller.addError(
            LgtmGroupsException.forFailure(failure),
          ),
        );
      },
      onCancel: () async {
        await indexSubscription?.cancel();
        await profileSubscription?.cancel();
        for (final subscription in groupSubscriptions.values) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<List<LgtmGroup>> _readGroupsFor(LgtmMember member) async {
    // The member's own list of groups, then each group in it. A group that has
    // been deleted since the index was written simply is not there to read.
    final index = await _database.ref('userGroups/${member.id}').get();
    final profiles = await _readProfiles();

    final groups = <LgtmGroup>[];
    for (final entry in jsonAsMap(index.value).entries) {
      if (entry.value != true) continue;
      final snapshot = await _database.ref('groups/${entry.key}').get();
      final raw = jsonAsMap(snapshot.value);
      if (raw.isEmpty) continue;
      groups.add(_groupFrom(entry.key, raw, profiles));
    }

    // Newest first, which is the order the hub shows. A group with no timestamp
    // (written before this field existed) sorts last rather than first.
    groups.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
    return groups;
  }

  @override
  Future<LgtmGroup> createGroup({
    required String name,
    required LgtmMember member,
  }) async {
    try {
      final group = await _createGroup(name, member);
      return group;
    } catch (failure) {
      throw LgtmGroupsException.forFailure(
        failure,
        what: 'save your new group',
      );
    }
  }

  Future<LgtmGroup> _createGroup(String name, LgtmMember member) async {
    final code = newInviteCode();
    final ref = _database.ref('groups').push();
    final gid = ref.key;
    if (gid == null) {
      throw const LgtmGroupsException('Could not start a new group.');
    }

    final groupRef = _database.ref('groups/$gid');
    await groupRef.set({
      ...LgtmGroup(
        id: gid,
        name: name.trim(),
        kind: LgtmGroupKind.home,
        inviteCode: code,
        ownerId: member.id,
        members: [member],
      ).toJson(),
      // The database stamps the time with its own clock, so every device agrees
      // on when a group was made. The model keeps a real number, which only
      // exists once the record has been read back.
      'createdAt': ServerValue.timestamp,
    });

    // The code and the owner's own list entry follow as separate writes. They
    // cannot be one update: writing at the root needs write access at the root,
    // which the rules refuse on purpose. So instead the group is taken back out
    // if either of them is turned down, because a group with no code cannot be
    // joined and a code pointing at nothing cannot be redeemed.
    try {
      await _database.ref('inviteCodes/$code').set(gid);
      await _database.ref('userGroups/${member.id}/$gid').set(true);
    } catch (_) {
      await _undo(groupRef.remove());
      rethrow;
    }

    // Read it back rather than trusting the local copy: the server has replaced
    // the timestamp placeholder by now, and the read also proves the write was
    // allowed by the rules.
    final snapshot = await groupRef.get();
    return _groupFrom(gid, jsonAsMap(snapshot.value), await _readProfiles());
  }

  @override
  Future<LgtmGroup> joinWithCode({
    required String code,
    required LgtmMember member,
  }) async {
    try {
      final group = await _joinWithCode(code, member);
      return group;
    } catch (failure) {
      throw LgtmGroupsException.forFailure(failure, what: 'join that group');
    }
  }

  Future<LgtmGroup> _joinWithCode(String code, LgtmMember member) async {
    const unknown =
        'We could not find a group with that code. Check it and try again.';

    final gid = await _database
        .ref('inviteCodes/${code.trim().toUpperCase()}')
        .get();
    final id = gid.value;
    if (id is! String || id.isEmpty) throw const LgtmGroupsException(unknown);

    // Joining writes the member's id into the group, and the group into their
    // own list, and both writes name only themselves. The group itself is
    // unreadable until the first of them lands, which is the point: a code is
    // what gets somebody in, not a group id somebody guessed. Writing a name
    // that is already there changes nothing, so joining twice is free.
    await _database.ref('groups/$id/members/${member.id}').set(true);
    await _database.ref('userGroups/${member.id}/$id').set(true);

    final groupRef = _database.ref('groups/$id');
    final raw = jsonAsMap((await groupRef.get()).value);
    if (raw.isEmpty) {
      // The code outlived the group behind it, so undo the two writes above
      // rather than leaving this member in a group that is not there. An undo
      // that is itself turned down must not replace the one sentence the
      // member needs to read.
      await _undo(groupRef.child('members/${member.id}').remove());
      await _undo(_database.ref('userGroups/${member.id}/$id').remove());
      throw const LgtmGroupsException(unknown);
    }
    return _groupFrom(id, raw, await _readProfiles());
  }

  /// Best effort cleanup: swallows the failure and moves on, because the caller
  /// is already on its way to explaining something the member can act on, and
  /// a leftover row is a stale group card rather than a broken one.
  Future<void> _undo(Future<void> write) async {
    try {
      await write;
    } catch (_) {
      // Nothing to do about it.
    }
  }

  LgtmGroup _groupFrom(
    String id,
    Map<String, Object?> raw,
    Map<String, LgtmUser> profiles, {
    Map<String, Object?>? members,
  }) => LgtmGroup.fromJson(
    id,
    raw,
    members: [
      for (final entry in (members ?? jsonAsMap(raw['members'])).entries)
        if (entry.value == true)
          LgtmMember.fromUser(
            profiles[entry.key] ??
                LgtmUser(uid: entry.key, displayName: 'Member', email: ''),
          ),
    ],
  );

  /// Reads the display names the group cards need.
  ///
  /// `publicProfiles` and not `users`: the rules let any signed in person read
  /// a name, but keep every profile in `users` readable only by the person it
  /// belongs to, so this cannot pull the whole directory of email addresses.
  Future<Map<String, LgtmUser>> _readProfiles() async {
    final snapshot = await _database.ref('publicProfiles').get();
    return {
      for (final entry in jsonAsMap(snapshot.value).entries)
        if (entry.value is Map)
          entry.key: LgtmUser.fromJson(entry.key, jsonAsMap(entry.value)),
    };
  }

  /// Invite codes avoid the characters people misread (0/O, 1/I/L) so a code
  /// can be read out loud over a table.
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String newInviteCode([Random? random]) {
    final source = random ?? Random.secure();
    return String.fromCharCodes(
      List<int>.generate(
        5,
        (_) => alphabet.codeUnitAt(source.nextInt(alphabet.length)),
      ),
    );
  }
}
