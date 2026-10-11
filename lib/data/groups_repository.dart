import 'package:firebase_core/firebase_core.dart';

import '../models/group.dart';
import '../models/member.dart';

/// Re-exported through `app/groups_store.dart` so screens keep importing one
/// file.
export '../models/group.dart';
export '../models/group_session.dart';
export '../models/member.dart';

/// How a group read or write failed, in words a form can put on screen.
class LgtmGroupsException implements Exception {
  const LgtmGroupsException(this.message);

  /// A whole sentence, already trimmed and ready to show.
  final String message;

  @override
  String toString() => 'LgtmGroupsException: $message';

  /// Turns whatever the storage threw into a sentence, so a screen never has to
  /// show a driver error and never has to catch something it did not expect.
  ///
  /// [what] is the thing being attempted, so a write does not get told it could
  /// not read. A failure that is already a sentence of ours passes straight
  /// through, which is how a deliberate message like "no group has that code"
  /// survives the trip.
  factory LgtmGroupsException.forFailure(
    Object failure, {
    String what = 'read your groups',
  }) {
    if (failure is LgtmGroupsException) return failure;

    final code = switch (failure) {
      FirebaseException(:final code) => code,
      _ => null,
    };

    return LgtmGroupsException(switch (code) {
      'permission-denied' =>
        'LGTM could not $what. Check your connection and try again.',
      'unavailable' || 'network-request-failed' =>
        'No connection to LGTM right now. Check your network and try again.',
      'deadline-exceeded' =>
        'LGTM took too long to answer. Try again in a moment.',
      _ => 'Something went wrong while trying to $what. Try again.',
    });
  }
}

/// Everything the app needs from "my groups".
///
/// [LgtmGroupsStore] is the only caller. Screens go through the store, so
/// Realtime Database remains isolated from the screens.
///
/// The acting [LgtmMember] is passed in rather than held, so the repository
/// never has its own idea of who is signed in and can never disagree with the
/// session.
abstract class LgtmGroupsRepository {
  /// The groups to put on the hub, newest first.
  ///
  /// The Realtime Database implementation queries on `members/{uid}`, so it
  /// can only see groups the member is in.
  Future<List<LgtmGroup>> loadGroups({required LgtmMember member});

  /// Watches group changes. Implementations without a live data source emit the
  /// current result once; Firebase implementations can keep the stream live.
  Stream<List<LgtmGroup>> watchGroups({required LgtmMember member}) =>
      Stream<List<LgtmGroup>>.fromFuture(loadGroups(member: member));

  /// Creates a group owned by [member] and returns it.
  Future<LgtmGroup> createGroup({
    required String name,
    required LgtmMember member,
  });

  /// Adds [member] to the group whose invite code is [code], and returns the
  /// group as it stands afterwards, which is the group itself when the member
  /// was already in it.
  ///
  /// Throws [LgtmGroupsException] when no group has that code.
  Future<LgtmGroup> joinWithCode({
    required String code,
    required LgtmMember member,
  });

  /// Removes [member] from the group and cleans both membership indexes.
  ///
  /// If the owner leaves, ownership is transferred to the first remaining
  /// member. A group with no remaining members is deleted.
  Future<void> leaveGroup({
    required LgtmGroup group,
    required LgtmMember member,
  }) => throw UnimplementedError('This repository does not support leaving.');
}
