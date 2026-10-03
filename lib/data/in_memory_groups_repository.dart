import 'package:flutter/material.dart';

import 'groups_repository.dart';
import 'realtime_groups_repository.dart';

/// The mock that stands in for Realtime Database while there is no project to
/// talk to.
///
/// It holds this account's groups in memory, waits [delay] on every call so the
/// hub keeps showing a real loading state, and never touches the network or the
/// disk. [seed] replaces the groups, so a test can start from a known list or
/// an empty one.
class LgtmInMemoryGroupsRepository implements LgtmGroupsRepository {
  LgtmInMemoryGroupsRepository({
    this.delay = const Duration(milliseconds: 600),
    List<LgtmGroup>? seed,
  }) : _groups = [...seed ?? mockGroups()];

  /// How long every call pretends to take.
  final Duration delay;

  final List<LgtmGroup> _groups;

  @override
  Future<List<LgtmGroup>> loadGroups({required LgtmMember member}) async {
    await Future<void>.delayed(delay);
    return List<LgtmGroup>.unmodifiable(_groups);
  }

  @override
  Future<LgtmGroup> createGroup({
    required String name,
    required LgtmMember member,
  }) async {
    await Future<void>.delayed(delay);

    final group = LgtmGroup(
      id: 'g${_groups.length + 1}',
      name: name.trim(),
      kind: LgtmGroupKind.home,
      inviteCode: _newInviteCode(),
      ownerId: member.id,
      members: [member],
      sessions: const [],
    );
    _groups.insert(0, group);
    return group;
  }

  @override
  Future<LgtmGroup> joinWithCode({
    required String code,
    required LgtmMember member,
  }) async {
    await Future<void>.delayed(delay);

    final wanted = code.trim().toLowerCase();
    LgtmGroup? match;
    for (final group in _groups) {
      if (group.inviteCode.toLowerCase() == wanted) {
        match = group;
        break;
      }
    }

    if (match == null) {
      throw const LgtmGroupsException(
        'We could not find a group with that code. Check it and try again.',
      );
    }

    if (match.members.any((inGroup) => inGroup.id == member.id)) return match;

    final joined = match.copyWith(members: [...match.members, member]);
    _groups
      ..remove(match)
      ..insert(0, joined);
    return joined;
  }

  /// The same code shape the real repository writes, so a code pasted from one
  /// behaves the same in the other.
  String _newInviteCode() => RealtimeGroupsRepository.newInviteCode();
}

/// The signed in member the mock starts from, until a real profile exists.
const lgtmMockMember = LgtmMember(
  id: 'u0',
  displayName: 'Purva',
  avatarColor: Color(0xFF4A4A4A),
);

/// The groups the app starts with, straight from the design: Roommates with
/// three finished sessions, and Hackathon Squad with none.
List<LgtmGroup> mockGroups() => [
  LgtmGroup(
    id: 'g1',
    name: 'Roommates',
    kind: LgtmGroupKind.home,
    inviteCode: 'vYzA1',
    ownerId: lgtmMockMember.id,
    members: const [
      lgtmMockMember,
      LgtmMember(
        id: 'u1',
        displayName: 'Nikhil',
        avatarColor: Color(0xFF2F5D5B),
      ),
      LgtmMember(
        id: 'u2',
        displayName: 'Aisha',
        avatarColor: Color(0xFF4B3F63),
      ),
      LgtmMember(id: 'u3', displayName: 'Dev', avatarColor: Color(0xFF5B4A3A)),
    ],
    sessions: const [
      LgtmGroupSession(
        id: 's1',
        activity: 'Dinner',
        winnerName: 'Taco Bell',
        winnerIcon: Icons.lunch_dining,
        date: '12 Mar',
      ),
      LgtmGroupSession(
        id: 's2',
        activity: 'Lunch',
        winnerName: 'Sushi Zen',
        winnerIcon: Icons.ramen_dining,
        date: '28 Feb',
      ),
      LgtmGroupSession(
        id: 's3',
        activity: 'Dinner',
        winnerName: 'Burger King',
        winnerIcon: Icons.fastfood,
        date: '21 Feb',
      ),
    ],
  ),
  LgtmGroup(
    id: 'g2',
    name: 'Hackathon Squad',
    kind: LgtmGroupKind.work,
    inviteCode: 'x7ZA1',
    ownerId: lgtmMockMember.id,
    members: const [
      lgtmMockMember,
      LgtmMember(
        id: 'u4',
        displayName: 'Meera',
        avatarColor: Color(0xFF2F5D5B),
      ),
      LgtmMember(
        id: 'u5',
        displayName: 'Kabir',
        avatarColor: Color(0xFF4B3F63),
      ),
    ],
    sessions: const [],
  ),
];
