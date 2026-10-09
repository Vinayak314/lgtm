import '../models/option_card.dart';
import '../models/session.dart';

/// Exception thrown when a session operation fails.
class LgtmSessionException implements Exception {
  const LgtmSessionException(this.message);
  final String message;

  @override
  String toString() => 'LgtmSessionException: $message';
}

/// Abstract contract for real-time session management.
abstract class LgtmSessionRepository {
  /// Creates a new session in Firebase Realtime Database.
  ///
  /// Host fetches up to 15 options using TMDB or Places API and stores them in the session.
  Future<LgtmSession> createSession({
    required String groupId,
    required String hostId,
    required SessionCategory category,
    required List<OptionCard> cards,
    double radiusMiles = 5.0,
  });

  /// Real-time stream of session updates (lobby members, status, cards, votes, winner).
  Stream<LgtmSession?> watchSession(String sessionId);

  /// Allows a member to join the lobby before swiping begins.
  Future<void> joinLobby({
    required String sessionId,
    required String userId,
  });

  /// Host locks active participants and starts swiping (`status = active`).
  Future<void> beginSwiping({
    required String sessionId,
  });

  /// Records a user's Yes/No swipe on a specific card.
  Future<void> submitVote({
    required String sessionId,
    required String cardId,
    required String userId,
    required bool liked,
  });

  /// Marks a user as finished with their 15 cards.
  Future<void> markUserFinished({
    required String sessionId,
    required String userId,
  });

  /// Evaluates unanimous or closest-match consensus and updates winner atomically.
  Future<SessionWinner?> checkAndDeclareWinner({
    required String sessionId,
    required LgtmSession session,
  });
}
