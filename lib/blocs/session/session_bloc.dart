import 'dart:async';

import '../../data/session_repository.dart';
import '../../models/option_card.dart';
import '../../models/session.dart';
import '../../services/movie_api.dart';
import '../../services/places_api.dart';
import 'session_event.dart';
import 'session_state.dart';

/// BLoC managing live session state, streams, swipe sync, and winner detection.
class SessionBloc {
  SessionBloc({
    required LgtmSessionRepository repository,
    required String currentUserId,
    MovieApiService? movieApi,
    PlacesApiService? placesApi,
  }) : _repository = repository,
       _currentUserId = currentUserId,
       _movieApi = movieApi ?? MovieApiService(),
       _placesApi = placesApi ?? PlacesApiService() {
    // asyncMap runs one handler at a time, so a handler that is waiting on
    // the network can never emit a stale state over a newer one.
    _eventController.stream
        .asyncMap(_handleEvent)
        .listen(
          (_) {},
          onError: (Object error) => _emit(SessionErrorState('$error')),
        );
  }

  final LgtmSessionRepository _repository;
  final String _currentUserId;
  final MovieApiService _movieApi;
  final PlacesApiService _placesApi;

  final _eventController = StreamController<SessionEvent>();
  final _stateController = StreamController<SessionState>.broadcast();

  StreamSubscription<LgtmSession?>? _sessionSubscription;

  SessionState _currentState = const SessionLoadingState();

  /// Set once this device has asked for the current user to be marked
  /// finished, so the write is not repeated on every update.
  bool _finishRequested = false;

  /// Why the host could not save the winner. Kept so the error stays on
  /// screen instead of being retried on every update.
  String? _declareError;

  /// Input sink for dispatching events.
  Sink<SessionEvent> get eventSink => _eventController.sink;

  /// Output stream of states.
  Stream<SessionState> get stateStream => _stateController.stream;

  SessionState get currentState => _currentState;

  void add(SessionEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _emit(SessionState state) {
    _currentState = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  Future<void> _handleEvent(SessionEvent event) async {
    if (event is SessionStartedEvent) {
      await _onStarted(event);
    } else if (event is JoinLobbyEvent) {
      await _onJoinLobby(event);
    } else if (event is RejoinSessionEvent) {
      await _onRejoinSession(event);
    } else if (event is BeginSwipingEvent) {
      await _onBeginSwiping(event);
    } else if (event is CardSwipedEvent) {
      await _onCardSwiped(event);
    } else if (event is SessionUpdatedEvent) {
      await _onSessionUpdated(event);
    }
  }

  Future<void> _onStarted(SessionStartedEvent event) async {
    _emit(const SessionLoadingState(message: 'Fetching options...'));
    try {
      final category = event.categoryName.toLowerCase() == 'movies'
          ? SessionCategory.movie
          : SessionCategory.food;

      final List<OptionCard> cards;
      if (category == SessionCategory.movie) {
        cards = await _movieApi.fetchMovieDeck(limit: 5);
      } else {
        cards = await _placesApi.fetchPlacesDeck(
          radiusMiles: event.radiusMiles,
          limit: 5,
        );
      }

      if (cards.length < 3) {
        throw const LgtmSessionException(
          'There are not enough options to start a session.',
        );
      }

      final session = await _repository.createSession(
        groupId: event.groupId,
        hostId: _currentUserId,
        category: category,
        cards: cards,
        radiusMiles: event.radiusMiles,
      );

      _subscribeToSession(session.id);
    } catch (error) {
      _emit(SessionErrorState('Failed to create session: $error'));
    }
  }

  Future<void> _onJoinLobby(JoinLobbyEvent event) async {
    _emit(const SessionLoadingState(message: 'Joining session...'));
    try {
      await _repository.joinLobby(
        sessionId: event.sessionId,
        userId: _currentUserId,
      );
      _subscribeToSession(event.sessionId);
    } catch (e) {
      _emit(SessionErrorState('Failed to join session: $e'));
    }
  }

  /// Rejoin an active or finished session without attempting to write to
  /// participants. Just subscribe to the stream — _onSessionUpdated will
  /// recover the correct UI state from Firebase.
  Future<void> _onRejoinSession(RejoinSessionEvent event) async {
    _emit(const SessionLoadingState(message: 'Reconnecting...'));
    _subscribeToSession(event.sessionId);
  }

  Future<void> _onBeginSwiping(BeginSwipingEvent event) async {
    try {
      await _repository.beginSwiping(sessionId: event.sessionId);
    } catch (e) {
      _emit(SessionErrorState('Failed to start session: $e'));
    }
  }

  Future<void> _onCardSwiped(CardSwipedEvent event) async {
    // Swiping freezes once the session has moved on (a winner, or waiting).
    if (_currentState is! SessionSwipingState) return;

    // The vote's local echo through watchSession moves the deck on, so the
    // event queue does not wait for the server to acknowledge the write.
    unawaited(
      _repository
          .submitVote(
            sessionId: event.sessionId,
            cardId: event.cardId,
            userId: _currentUserId,
            liked: event.liked,
          )
          .catchError((Object e) {
            _emit(SessionErrorState('Failed to submit vote: $e'));
          }),
    );
  }

  Future<void> _onSessionUpdated(SessionUpdatedEvent event) async {
    final session = event.session;
    if (session == null) {
      _emit(const SessionErrorState('Session not found'));
      return;
    }

    // ---- Check winner first (already declared in Firebase) ----
    if (session.winner != null) {
      _emitWon(session, session.winner!);
      return;
    }

    // ---- Host declares the winner as soon as the votes decide one ----
    // A unanimous Yes ends the session straight away; the closest match only
    // once everyone has finished. Firebase rules only allow the host to write
    // winner + status, so other participants receive the finished snapshot
    // through the stream. The host checks on every update, including after a
    // rejoin, so a session that was decided while it was away still ends.
    if (session.status == SessionStatus.active &&
        session.hostId == _currentUserId &&
        session.decidedWinner != null) {
      if (_declareError != null) {
        _emit(SessionErrorState(_declareError!));
        return;
      }
      try {
        final declaredWinner = await _repository.checkAndDeclareWinner(
          sessionId: session.id,
          session: session,
        );
        if (declaredWinner != null) {
          _emitWon(
            session.copyWith(
              status: SessionStatus.finished,
              winner: declaredWinner,
            ),
            declaredWinner,
          );
          return;
        }
      } catch (e) {
        _declareError = 'Could not finish the session: $e';
        _emit(SessionErrorState(_declareError!));
        return;
      }
    }

    switch (session.status) {
      case SessionStatus.lobby:
        _emit(
          SessionLobbyState(
            session: session,
            isHost: session.hostId == _currentUserId,
          ),
        );
        break;

      case SessionStatus.active:
        // Progress comes from the votes stored in Firebase, so a fresh bloc
        // (e.g. after back-press) picks up on the first card not voted on.
        final nextIndex = session.nextCardIndexFor(_currentUserId);
        if (nextIndex == -1 || session.hasFinished(_currentUserId)) {
          _markFinished(session);
          _emit(
            SessionWaitingState(
              session: session,
              finishedCount: session.finishedIds.length,
              totalParticipants: session.participantIds.length,
            ),
          );
        } else {
          _emit(
            SessionSwipingState(
              session: session,
              currentIndex: nextIndex,
              cards: session.cards,
            ),
          );
        }
        break;

      case SessionStatus.finished:
        // Session finished but winner field missing (edge case / stale data).
        // Show waiting rather than a blank screen.
        _emit(
          SessionWaitingState(
            session: session,
            finishedCount: session.finishedIds.length,
            totalParticipants: session.participantIds.length,
          ),
        );
        break;
    }
  }

  void _emitWon(LgtmSession session, SessionWinner winner) {
    final winnerCard = session.cards.firstWhere(
      (c) => c.id == winner.cardId,
      orElse: () => session.cards.first,
    );
    _emit(
      SessionWonState(
        session: session,
        winnerCard: winnerCard,
        winnerType: winner.type,
      ),
    );
  }

  /// Marks the current user finished once they have voted on every card.
  /// This runs from the stream rather than the swipe handler, so it still
  /// happens when a vote's echo beats its acknowledgement, or when the app
  /// was closed between the last swipe and the write.
  void _markFinished(LgtmSession session) {
    if (_finishRequested ||
        session.hasFinished(_currentUserId) ||
        !session.isParticipant(_currentUserId)) {
      return;
    }
    _finishRequested = true;
    unawaited(
      _repository
          .markUserFinished(sessionId: session.id, userId: _currentUserId)
          .catchError((Object e) {
            _emit(SessionErrorState('Failed to finish swiping: $e'));
          }),
    );
  }

  void _subscribeToSession(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _repository
        .watchSession(sessionId)
        .listen(
          (session) {
            add(SessionUpdatedEvent(session));
          },
          onError: (error) {
            _emit(SessionErrorState('Realtime sync error: $error'));
          },
        );
  }

  void dispose() {
    _sessionSubscription?.cancel();
    _eventController.close();
    _stateController.close();
  }
}
