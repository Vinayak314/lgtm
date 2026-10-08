import 'dart:async';

import '../models/option_card.dart';
import '../models/session.dart';
import 'session_repository.dart';

/// In-memory implementation of [LgtmSessionRepository] for demo mode (--dart-define=LGTM_DEMO=true).
class InMemorySessionRepository implements LgtmSessionRepository {
  final Map<String, LgtmSession> _sessions = {};
  final Map<String, StreamController<LgtmSession?>> _controllers = {};

  StreamController<LgtmSession?> _getController(String id) {
    return _controllers.putIfAbsent(id, () => StreamController<LgtmSession?>.broadcast());
  }

  void _notify(String id) {
    if (_controllers.containsKey(id)) {
      _controllers[id]!.add(_sessions[id]);
    }
  }

  @override
  Future<LgtmSession> createSession({
    required String groupId,
    required String hostId,
    required SessionCategory category,
    required List<OptionCard> cards,
    double radiusMiles = 5.0,
  }) async {
    final sessionId = 'demo_session_${DateTime.now().millisecondsSinceEpoch}';
    final session = LgtmSession(
      id: sessionId,
      groupId: groupId,
      hostId: hostId,
      category: category,
      radius: radiusMiles,
      status: SessionStatus.lobby,
      cards: cards,
      participantIds: {hostId, 'demo_user_2', 'demo_user_3'},
      votes: const {},
      finishedIds: const {},
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    _sessions[sessionId] = session;
    _notify(sessionId);
    return session;
  }

  @override
  Stream<LgtmSession?> watchSession(String sessionId) async* {
    yield _sessions[sessionId];
    yield* _getController(sessionId).stream;
  }

  @override
  Future<void> joinLobby({
    required String sessionId,
    required String userId,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) return;

    if (!session.participantIds.contains(userId)) {
      _sessions[sessionId] = session.copyWith(
        participantIds: {...session.participantIds, userId},
      );
      _notify(sessionId);
    }
  }

  @override
  Future<void> beginSwiping({
    required String sessionId,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) return;

    _sessions[sessionId] = session.copyWith(
      status: SessionStatus.active,
    );
    _notify(sessionId);
  }

  @override
  Future<void> submitVote({
    required String sessionId,
    required String cardId,
    required String userId,
    required bool liked,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) return;

    final updatedCardVotes = Map<String, bool>.from(session.votes[cardId] ?? {});
    updatedCardVotes[userId] = liked;

    final updatedVotes = Map<String, Map<String, bool>>.from(session.votes);
    updatedVotes[cardId] = updatedCardVotes;

    _sessions[sessionId] = session.copyWith(votes: updatedVotes);
    _notify(sessionId);
  }

  @override
  Future<void> markUserFinished({
    required String sessionId,
    required String userId,
  }) async {
    final session = _sessions[sessionId];
    if (session == null) return;

    if (!session.finishedIds.contains(userId)) {
      _sessions[sessionId] = session.copyWith(
        finishedIds: {...session.finishedIds, userId},
      );
      _notify(sessionId);
    }
  }

  @override
  Future<SessionWinner?> checkAndDeclareWinner({
    required String sessionId,
    required LgtmSession session,
  }) async {
    final current = _sessions[sessionId] ?? session;
    if (current.winner != null) return current.winner;

    final unanimousCard = current.findUnanimousCard();
    if (unanimousCard != null) {
      final winner = SessionWinner(
        cardId: unanimousCard,
        type: WinnerType.unanimous,
      );
      _sessions[sessionId] = current.copyWith(
        winner: winner,
        status: SessionStatus.finished,
      );
      _notify(sessionId);
      return winner;
    }

    if (current.allParticipantsFinished) {
      final closest = current.closestMatchCard();
      if (closest != null) {
        final winner = SessionWinner(
          cardId: closest.id,
          type: WinnerType.closest,
        );
        _sessions[sessionId] = current.copyWith(
          winner: winner,
          status: SessionStatus.finished,
        );
        _notify(sessionId);
        return winner;
      }
    }

    return null;
  }
}
