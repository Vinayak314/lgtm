import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/option_card.dart';
import '../models/session.dart';
import 'session_repository.dart';

/// Live Firebase Realtime Database implementation of [LgtmSessionRepository].
class RealtimeSessionRepository implements LgtmSessionRepository {
  RealtimeSessionRepository({FirebaseDatabase? database})
    : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;

  DatabaseReference get _sessionsRef => _db.ref('sessions');
  DatabaseReference get _groupsRef => _db.ref('groups');

  @override
  Future<String?> activeSessionId(String groupId) async {
    final value =
        (await _groupsRef.child('$groupId/activeSession').get()).value;
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Future<LgtmSession> createSession({
    required String groupId,
    required String hostId,
    required SessionCategory category,
    required List<OptionCard> cards,
    double radiusMiles = 5.0,
  }) async {
    final groupSnapshot = await _groupsRef.child(groupId).get();
    final groupValue = groupSnapshot.value;
    if (groupValue is Map &&
        groupValue['activeSession'] is String &&
        (groupValue['activeSession'] as String).isNotEmpty) {
      throw const LgtmSessionException(
        'This group already has an active session. Join its lobby instead.',
      );
    }

    final ref = _sessionsRef.push();
    final sessionId = ref.key!;
    final now = DateTime.now().millisecondsSinceEpoch;

    final session = LgtmSession(
      id: sessionId,
      groupId: groupId,
      hostId: hostId,
      category: category,
      radius: radiusMiles,
      status: SessionStatus.lobby,
      cards: cards,
      participantIds: {hostId},
      votes: const {},
      finishedIds: const {},
      createdAt: now,
    );

    final sessionMap = session.toJson();

    await ref.set(sessionMap);
    // Set activeSession banner link on group
    await _groupsRef.child(groupId).child('activeSession').set(sessionId);

    return session;
  }

  @override
  Future<LgtmSession?> fetchSession(String sessionId) async {
    final snapshot = await _sessionsRef.child(sessionId).get();
    final value = snapshot.value;
    if (value == null || value is! Map) return null;
    final map = Map<String, Object?>.from(
      value.map((k, v) => MapEntry(k.toString(), v)),
    );
    return LgtmSession.fromJson(sessionId, map);
  }

  @override
  Stream<LgtmSession?> watchSession(String sessionId) {
    return _sessionsRef.child(sessionId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return null;
      if (value is! Map) return null;

      final map = Map<String, Object?>.from(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
      return LgtmSession.fromJson(sessionId, map);
    });
  }

  @override
  Future<void> joinLobby({
    required String sessionId,
    required String userId,
  }) async {
    final snapshot = await _sessionsRef.child(sessionId).get();
    if (snapshot.value == null) {
      throw const LgtmSessionException('This session is no longer available.');
    }
    final sessionMap = snapshot.value is Map
        ? Map<String, Object?>.from(
            (snapshot.value as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : const <String, Object?>{};

    final status = SessionStatus.fromWire(sessionMap['status']);

    if (status == SessionStatus.lobby) {
      // Normal lobby join — add as participant.
      final ref = _sessionsRef
          .child(sessionId)
          .child('participants')
          .child(userId);
      await ref.set(true);
      return;
    }

    // Session already active or finished. If the user is already a
    // participant this is a harmless rejoin — let the bloc handle it
    // by subscribing to the stream. If they are NOT a participant,
    // they missed the lobby window.
    final participants = sessionMap['participants'];
    final isParticipant = participants is Map && participants[userId] == true;

    if (!isParticipant) {
      throw const LgtmSessionException(
        'This session has already started voting.',
      );
    }
    // Already a participant of an active/finished session — no-op.
  }

  @override
  Future<void> beginSwiping({required String sessionId}) async {
    final ref = _sessionsRef.child(sessionId);
    await ref.update({'status': SessionStatus.active.wire});
  }

  @override
  Future<void> submitVote({
    required String sessionId,
    required String cardId,
    required String userId,
    required bool liked,
  }) async {
    final voteRef = _sessionsRef
        .child(sessionId)
        .child('votes')
        .child(cardId)
        .child(userId);
    await voteRef.set(liked);
  }

  @override
  Future<void> markUserFinished({
    required String sessionId,
    required String userId,
  }) async {
    final ref = _sessionsRef.child(sessionId).child('finished').child(userId);
    await ref.set(true);
  }

  @override
  Future<SessionWinner?> checkAndDeclareWinner({
    required String sessionId,
    required LgtmSession session,
  }) async {
    final winner = session.decidedWinner;
    if (winner == null) return null;

    // One atomic multi-location update, not a transaction on `sessions/{sid}`:
    // the rules only allow that node to be written when it is created, so a
    // whole-node write is rejected. Here each path is checked against its own
    // rule, and `winner` is write-once, so a second declaration fails instead
    // of overwriting the first. Ending the session and clearing the group's
    // active session land together or not at all.
    final groupId = session.groupId;
    await _db.ref().update({
      'sessions/$sessionId/winner': winner.toJson(),
      'sessions/$sessionId/status': SessionStatus.finished.wire,
      if (groupId.isNotEmpty) ...{
        'groups/$groupId/activeSession': null,
        'groups/$groupId/sessions/$sessionId': {
          'activity': session.category == SessionCategory.movie
              ? 'Movies'
              : 'Food',
          'winnerName': _winnerName(session, winner.cardId),
          'date': _formatDate(session.createdAt),
        },
      },
    });
    return winner;
  }

  String _winnerName(LgtmSession session, String cardId) {
    for (final card in session.cards) {
      if (card.id == cardId) return card.title;
    }
    return 'Selected option';
  }

  String _formatDate(Object? raw) {
    final milliseconds = raw is num ? raw.toInt() : null;
    if (milliseconds == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${date.day.toString().padLeft(2, '0')} '
        '${_months[date.month - 1]}';
  }

  static const _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
