import 'dart:math';

import 'package:flutter/material.dart';

/// One person in a group.
///
/// [avatarColor] stands in for the member's photo until the real image URLs
/// arrive with the Firebase work.
class LgtmMember {
  const LgtmMember({
    required this.id,
    required this.displayName,
    required this.avatarColor,
  });

  final String id;
  final String displayName;
  final Color avatarColor;
}

/// What a group is for. Decides the icon on its card.
enum LgtmGroupKind { home, work }

/// A session the group already finished: what they were deciding, what they
/// agreed on, and when.
class LgtmGroupSession {
  const LgtmGroupSession({
    required this.id,
    required this.activity,
    required this.winnerName,
    required this.winnerIcon,
    required this.date,
  });

  final String id;
  final String activity;
  final String winnerName;

  /// Placeholder glyph for the winning option. The real card shows a photo
  /// once the option models land.
  final IconData winnerIcon;
  final String date;
}

/// A group: its invite code, its members and its finished sessions.
class LgtmGroup {
  const LgtmGroup({
    required this.id,
    required this.name,
    required this.kind,
    required this.inviteCode,
    required this.members,
    required this.sessions,
  });

  final String id;
  final String name;
  final LgtmGroupKind kind;
  final String inviteCode;
  final List<LgtmMember> members;
  final List<LgtmGroupSession> sessions;

  /// The link a member can share. Matches the invite URL in the design.
  String get inviteLink => 'lgtm.app/invite/$inviteCode';

  /// The three most recent wins, which is what the hub card shows.
  List<LgtmGroupSession> get recentWinners => sessions.take(3).toList();

  bool get hasWinners => sessions.isNotEmpty;

  LgtmGroup copyWith({List<LgtmMember>? members}) => LgtmGroup(
    id: id,
    name: name,
    kind: kind,
    inviteCode: inviteCode,
    members: members ?? this.members,
    sessions: sessions,
  );
}

/// The groups the signed in person belongs to, held in memory for the life of
/// the app.
///
/// This is deliberately a mock, exactly like [LgtmSession]: Realtime Database,
/// security rules and persistence are the backend items in TODO.md, so nothing
/// here touches the network or the disk. Screens only ever talk to this
/// object, so the real repository can slot in without touching a screen.
class LgtmGroupsStore extends ChangeNotifier {
  /// Builds a store. [seed] replaces the mock groups, so tests can start from
  /// a known list (or an empty one).
  LgtmGroupsStore({
    this.delay = const Duration(milliseconds: 600),
    List<LgtmGroup>? seed,
    LgtmMember? currentMember,
  }) : _groups = [...seed ?? _mockGroups()],
       currentMember = currentMember ?? _mockCurrentMember;

  /// How long [load], [createGroup] and [joinWithCode] pretend to take.
  final Duration delay;

  /// The signed in member. A mock until the real profile exists; the member
  /// lists mark this row as you.
  final LgtmMember currentMember;

  final List<LgtmGroup> _groups;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  /// False until [load] has finished, so the hub can show a loading state.
  bool get isReady => _ready;

  /// True while a create or a join is in flight.
  bool get isBusy => _busy;

  /// The last failure as a whole sentence a form can show as is.
  String? get error => _error;

  /// Newest first.
  List<LgtmGroup> get groups => List.unmodifiable(_groups);

  /// True when this member is already in the group.
  bool isMember(LgtmGroup group) =>
      group.members.any((member) => member.id == currentMember.id);

  LgtmGroup? groupById(String id) {
    for (final group in _groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  /// Loads the groups once. The hub calls this on its first build; calling it
  /// again does nothing.
  Future<void> load() async {
    if (_ready) return;
    await Future<void>.delayed(delay);
    _ready = true;
    notifyListeners();
  }

  /// Creates a group owned by [currentMember] and puts it at the top of the
  /// hub, then returns it so the caller can open it.
  Future<LgtmGroup> createGroup({required String name}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    await Future<void>.delayed(delay);

    final group = LgtmGroup(
      id: 'g${_groups.length + 1}',
      name: name.trim(),
      kind: LgtmGroupKind.home,
      inviteCode: _newInviteCode(),
      members: [currentMember],
      sessions: const [],
    );
    _groups.insert(0, group);

    _busy = false;
    notifyListeners();
    return group;
  }

  /// Joins with an invite code. Returns true when the group is in the hub
  /// afterwards, whether it was joined now or the member was in it already.
  Future<bool> joinWithCode(String code) async {
    _busy = true;
    _error = null;
    notifyListeners();

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
      _busy = false;
      _error =
          'We could not find a group with that code. Check it and try '
          'again.';
      notifyListeners();
      return false;
    }

    if (isMember(match)) {
      _busy = false;
      notifyListeners();
      return true;
    }

    _groups.remove(match);
    _groups.insert(
      0,
      match.copyWith(members: [...match.members, currentMember]),
    );

    _busy = false;
    notifyListeners();
    return true;
  }

  /// Clears the last failure message once the form has been edited.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Invite codes avoid the characters people misread (0/O, 1/I/L) so a code
  /// can be read out loud over a table.
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  String _newInviteCode() {
    final random = Random();
    return String.fromCharCodes(
      List<int>.generate(
        5,
        (_) => _alphabet.codeUnitAt(random.nextInt(_alphabet.length)),
      ),
    );
  }
}

const _mockCurrentMember = LgtmMember(
  id: 'u0',
  displayName: 'Purva',
  avatarColor: Color(0xFF4A4A4A),
);

/// The groups the app starts with, straight from the design: Roommates with
/// three finished sessions, and Hackathon Squad with none.
List<LgtmGroup> _mockGroups() => [
  LgtmGroup(
    id: 'g1',
    name: 'Roommates',
    kind: LgtmGroupKind.home,
    inviteCode: 'vYzA1',
    members: const [
      _mockCurrentMember,
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
    members: const [
      _mockCurrentMember,
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

/// Makes the one [LgtmGroupsStore] available to every route.
class LgtmGroupsScope extends InheritedNotifier<LgtmGroupsStore> {
  const LgtmGroupsScope({
    super.key,
    required LgtmGroupsStore store,
    required super.child,
  }) : super(notifier: store);

  /// Read the store and rebuild when it changes.
  static LgtmGroupsStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LgtmGroupsScope>()!.notifier!;

  /// Read the store without subscribing, for one off calls such as a
  /// submission.
  static LgtmGroupsStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LgtmGroupsScope>()!.notifier!;
}
