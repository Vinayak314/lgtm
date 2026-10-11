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
    _eventController.stream.listen(_handleEvent);
  }

  final LgtmSessionRepository _repository;
  final String _currentUserId;
  final MovieApiService _movieApi;
  final PlacesApiService _placesApi;

  final _eventController = StreamController<SessionEvent>();
  final _stateController = StreamController<SessionState>.broadcast();

  StreamSubscription<LgtmSession?>? _sessionSubscription;

  SessionState _currentState = const SessionLoadingState();
  int _localIndex = 0;

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
        cards = await _movieApi.fetchMovieDeck(limit: 6);
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
    _emit(const SessionLoadingState(message: 'Joining lobby...'));
    try {
      await _repository.joinLobby(
        sessionId: event.sessionId,
        userId: _currentUserId,
      );
      _subscribeToSession(event.sessionId);
    } catch (e) {
      _emit(SessionErrorState('Failed to join lobby: $e'));
    }
  }

  Future<void> _onBeginSwiping(BeginSwipingEvent event) async {
    try {
      await _repository.beginSwiping(sessionId: event.sessionId);
    } catch (e) {
      _emit(SessionErrorState('Failed to start session: $e'));
    }
  }

  Future<void> _onCardSwiped(CardSwipedEvent event) async {
    try {
      await _repository.submitVote(
        sessionId: event.sessionId,
        cardId: event.cardId,
        userId: _currentUserId,
        liked: event.liked,
      );

      _localIndex++;

      if (_currentState is SessionSwipingState) {
        final currentSwiping = _currentState as SessionSwipingState;

        if (_localIndex >= currentSwiping.cards.length) {
          await _repository.markUserFinished(
            sessionId: event.sessionId,
            userId: _currentUserId,
          );
        } else {
          _emit(
            SessionSwipingState(
              session: currentSwiping.session,
              currentIndex: _localIndex,
              cards: currentSwiping.cards,
            ),
          );
        }
      }
    } catch (e) {
      _emit(SessionErrorState('Failed to submit vote: $e'));
    }
  }

  Future<void> _onSessionUpdated(SessionUpdatedEvent event) async {
    final session = event.session;
    if (session == null) {
      _emit(const SessionErrorState('Session not found'));
      return;
    }

    // Check winner first
    if (session.winner != null) {
      final winnerCard = session.cards.firstWhere(
        (c) => c.id == session.winner!.cardId,
        orElse: () => session.cards.first,
      );
      _emit(
        SessionWonState(
          session: session,
          winnerCard: winnerCard,
          winnerType: session.winner!.type,
        ),
      );
      return;
    }

    // Only the host may finalize the session under the Firebase rules. The
    // other participants receive the finished snapshot through the stream.
    if (session.status == SessionStatus.active &&
        session.hostId == _currentUserId) {
      final declaredWinner = await _repository.checkAndDeclareWinner(
        sessionId: session.id,
        session: session,
      );
      if (declaredWinner != null) {
        final finishedSession = session.copyWith(
          status: SessionStatus.finished,
          winner: declaredWinner,
        );
        final winnerCard = finishedSession.cards.firstWhere(
          (c) => c.id == declaredWinner.cardId,
          orElse: () => finishedSession.cards.first,
        );
        _emit(
          SessionWonState(
            session: finishedSession,
            winnerCard: winnerCard,
            winnerType: declaredWinner.type,
          ),
        );
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
        if (session.finishedIds.contains(_currentUserId) ||
            _localIndex >= session.cards.length) {
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
              currentIndex: _localIndex,
              cards: session.cards,
            ),
          );
        }
        break;

      case SessionStatus.finished:
        if (session.winner != null) {
          final winnerCard = session.cards.firstWhere(
            (c) => c.id == session.winner!.cardId,
            orElse: () => session.cards.first,
          );
          _emit(
            SessionWonState(
              session: session,
              winnerCard: winnerCard,
              winnerType: session.winner!.type,
            ),
          );
        }
        break;
    }
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
