import '../../models/session.dart';

/// Base class for all Session events.
abstract class SessionEvent {
  const SessionEvent();
}

/// Host initializes a new session or member pings a session.
class SessionStartedEvent extends SessionEvent {
  const SessionStartedEvent({
    required this.groupId,
    required this.categoryName,
    this.radiusMiles = 5.0,
  });

  final String groupId;
  final String categoryName;
  final double radiusMiles;
}

/// Member joins the active lobby.
class JoinLobbyEvent extends SessionEvent {
  const JoinLobbyEvent({required this.sessionId});
  final String sessionId;
}

/// Host taps Begin in lobby.
class BeginSwipingEvent extends SessionEvent {
  const BeginSwipingEvent({required this.sessionId});
  final String sessionId;
}

/// User swiped a card (Yes or No).
class CardSwipedEvent extends SessionEvent {
  const CardSwipedEvent({
    required this.sessionId,
    required this.cardId,
    required this.liked,
  });

  final String sessionId;
  final String cardId;
  final bool liked;
}

/// Session stream emitted an update.
class SessionUpdatedEvent extends SessionEvent {
  const SessionUpdatedEvent(this.session);
  final LgtmSession? session;
}
