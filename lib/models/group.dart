import 'group_session.dart';
import 'json.dart';
import 'member.dart';

/// What a group is for. Decides the icon on its card, and is stored on the
/// group so the card looks the same on a device that never met the creator.
enum LgtmGroupKind {
  home('home'),
  work('work');

  const LgtmGroupKind(this.wire);

  /// The value written to the database.
  final String wire;

  static LgtmGroupKind fromWire(Object? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => LgtmGroupKind.home,
  );
}

/// A group: its invite code, its members and its finished sessions.
///
/// The record is `groups/{gid}`:
///
/// ```text
/// { name, code, ownerId, kind, activeSession, members: { uid: true } }
/// ```
///
/// [members] holds whole people because a card has to show names, while the
/// wire only holds ids. The repository resolves ids against `users/{uid}` and
/// hands the results to [LgtmGroup.fromJson], which keeps one list of members
/// instead of two that can disagree.
class LgtmGroup {
  const LgtmGroup({
    required this.id,
    required this.name,
    required this.kind,
    required this.inviteCode,
    this.ownerId = '',
    this.createdAt,
    this.members = const [],
    this.sessions = const [],
    this.activeSessionId,
  });

  final String id;
  final String name;
  final LgtmGroupKind kind;

  /// Short code people read out loud to join.
  final String inviteCode;

  /// Who created the group. Whoever hosts a session has to be a member, and the
  /// rules check this id.
  final String ownerId;

  /// When the group was created, in milliseconds since the epoch, written by the
  /// database's own clock. The hub's order comes from this, not from whatever
  /// order a read happened to return in.
  final int? createdAt;

  final List<LgtmMember> members;
  final List<LgtmGroupSession> sessions;

  /// The session the hub shows a "join" banner for, or null when the group has
  /// nothing running.
  final String? activeSessionId;

  /// Reads `groups/{gid}`. [members] must already be resolved from `users`.
  factory LgtmGroup.fromJson(
    String id,
    Map<String, Object?> json, {
    List<LgtmMember> members = const [],
    List<LgtmGroupSession> sessions = const [],
  }) => LgtmGroup(
    id: id,
    name: jsonAsString(json['name'], fallback: 'Group'),
    kind: LgtmGroupKind.fromWire(json['kind']),
    inviteCode: jsonAsString(json['code']),
    ownerId: jsonAsString(json['ownerId']),
    activeSessionId: switch (jsonAsString(json['activeSession'])) {
      '' => null,
      final sid => sid,
    },
    members: members,
    sessions: sessions,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'code': inviteCode,
    'ownerId': ownerId,
    'kind': kind.wire,
    'createdAt': createdAt,
    // Written even when null: the database treats a missing key as "unknown",
    // and the banner logic needs to see "no session" spelled out.
    'activeSession': activeSessionId,
    'members': {for (final member in members) member.id: true},
  };

  /// The ids only, which is what gets written and what the rules check.
  List<String> get memberIds => [for (final member in members) member.id];

  /// The link a member can share. Matches the invite URL in the design.
  String get inviteLink => 'lgtm.app/invite/$inviteCode';

  /// The three most recent wins, which is what the hub card shows.
  List<LgtmGroupSession> get recentWinners => sessions.take(3).toList();

  bool get hasWinners => sessions.isNotEmpty;

  bool get hasActiveSession => activeSessionId != null;

  LgtmGroup copyWith({
    List<LgtmMember>? members,
    List<LgtmGroupSession>? sessions,
    String? inviteCode,
    String? activeSessionId,
  }) => LgtmGroup(
    id: id,
    name: name,
    kind: kind,
    inviteCode: inviteCode ?? this.inviteCode,
    ownerId: ownerId,
    createdAt: createdAt,
    members: members ?? this.members,
    sessions: sessions ?? this.sessions,
    activeSessionId: activeSessionId ?? this.activeSessionId,
  );
}
