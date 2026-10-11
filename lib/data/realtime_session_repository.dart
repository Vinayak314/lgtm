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
    final session = await _sessionsRef.child(sessionId).get();
    if (session.value == null) {
      throw const LgtmSessionException('This session is no longer available.');
    }
    final ref = _sessionsRef
        .child(sessionId)
        .child('participants')
        .child(userId);
    await ref.set(true);
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
    final sessionRef = _sessionsRef.child(sessionId);

    // 1. Check for unanimous winner first
    final unanimousCard = session.findUnanimousCard();
    if (unanimousCard != null) {
      return _tryDeclareTransaction(
        sessionRef,
        cardId: unanimousCard,
        type: WinnerType.unanimous,
      );
    }

    // 2. Check if all participants finished for fallback Closest Match
    if (session.allParticipantsFinished) {
      final closest = session.closestMatchCard();
      if (closest != null) {
        return _tryDeclareTransaction(
          sessionRef,
          cardId: closest.id,
          type: WinnerType.closest,
        );
      }
    }

    return null;
  }

  Future<SessionWinner?> _tryDeclareTransaction(
    DatabaseReference sessionRef, {
    required String cardId,
    required WinnerType type,
  }) async {
    final result = await sessionRef.runTransaction((currentData) {
      if (currentData == null) return Transaction.abort();

      final map = Map<String, dynamic>.from(currentData as Map);
      if (map['winner'] != null) {
        return Transaction.abort(); // Someone already declared winner
      }

      map['winner'] = {'cardId': cardId, 'type': type.wire};
      map['status'] = SessionStatus.finished.wire;

      return Transaction.success(map);
    });

    if (result.committed) {
      final snap = result.snapshot;
      if (snap.value is Map) {
        final groupId = (snap.value as Map)['groupId']?.toString();
        if (groupId != null && groupId.isNotEmpty) {
          final winnerName = _winnerName(snap.value as Map, cardId);
          final category = (snap.value as Map)['category']?.toString();
          final date = _formatDate(
            (snap.value as Map)['createdAt'],
          );
          final sessionId = sessionRef.key;
          if (sessionId == null) {
            throw const LgtmSessionException(
              'The completed session has no identifier.',
            );
          }
          await _groupsRef.child(groupId).update({
            'activeSession': null,
            'sessions/$sessionId': {
              'activity': category == SessionCategory.movie.wire
                  ? 'Movies'
                  : 'Food',
              'winnerName': winnerName,
              'date': date,
            },
          });
        }
      }
      return SessionWinner(cardId: cardId, type: type);
    }
    return null;
  }

  String _winnerName(Map snapshot, String cardId) {
    final cards = snapshot['cards'];
    if (cards is List) {
      for (final card in cards) {
        if (card is Map && card['id']?.toString() == cardId) {
          return card['title']?.toString() ?? 'Selected option';
        }
      }
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
