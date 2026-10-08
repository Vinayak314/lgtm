import '../../models/option_card.dart';
import '../../models/session.dart';

/// Base class for all Session states.
abstract class SessionState {
  const SessionState();
}

/// Initial loading state when setting up or fetching cards.
class SessionLoadingState extends SessionState {
  const SessionLoadingState({this.message = 'Setting up session...'});
  final String message;
}

/// Lobby phase state.
class SessionLobbyState extends SessionState {
  const SessionLobbyState({
    required this.session,
    required this.isHost,
  });

  final LgtmSession session;
  final bool isHost;
}

/// Active swiping phase state.
class SessionSwipingState extends SessionState {
  const SessionSwipingState({
    required this.session,
    required this.currentIndex,
    required this.cards,
  });

  final LgtmSession session;
  final int currentIndex;
  final List<OptionCard> cards;

  bool get isDeckFinished => currentIndex >= cards.length;
}

/// Waiting state when a user finishes swiping all cards before the group.
class SessionWaitingState extends SessionState {
  const SessionWaitingState({
    required this.session,
    required this.finishedCount,
    required this.totalParticipants,
  });

  final LgtmSession session;
  final int finishedCount;
  final int totalParticipants;
}

/// Final winner declared state (Unanimous or Closest Match).
class SessionWonState extends SessionState {
  const SessionWonState({
    required this.session,
    required this.winnerCard,
    required this.winnerType,
  });

  final LgtmSession session;
  final OptionCard winnerCard;
  final WinnerType winnerType;
}

/// Error state.
class SessionErrorState extends SessionState {
  const SessionErrorState(this.errorMessage);
  final String errorMessage;
}
