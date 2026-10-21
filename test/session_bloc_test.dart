import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/blocs/session/session_bloc.dart';
import 'package:lgtm/blocs/session/session_event.dart';
import 'package:lgtm/blocs/session/session_state.dart';
import 'package:lgtm/data/session_repository.dart';
import 'package:lgtm/models/option_card.dart';
import 'package:lgtm/models/session.dart';
import 'package:lgtm/screens/session/swipe_screen.dart';

void main() {
  group('a live session ends as soon as the group has decided', () {
    test(
      'every card is shown once and the last vote marks you finished',
      () async {
        final repository = _FakeSessionRepository(
          _session(participants: {'host'}),
        );
        final host = _bloc(repository, 'host');
        await _settle();

        final shown = <int>[];
        while (host.currentState is SessionSwipingState) {
          final state = host.currentState as SessionSwipingState;
          shown.add(state.currentIndex);
          host.add(
            CardSwipedEvent(
              sessionId: 's1',
              cardId: state.cards[state.currentIndex].id,
              liked: false,
            ),
          );
          await _settle();
        }

        expect(shown, [0, 1, 2, 3, 4]);
        expect(repository.finishedCalls, ['host']);
        expect(host.currentState, isA<SessionWonState>());
      },
    );

    test('a unanimous Yes ends the session before the deck runs out', () async {
      final repository = _FakeSessionRepository(
        _session(participants: {'host', 'guest'}),
      );
      final host = _bloc(repository, 'host');
      final guest = _bloc(repository, 'guest');
      await _settle();

      host.add(
        const CardSwipedEvent(sessionId: 's1', cardId: 'c0', liked: true),
      );
      guest.add(
        const CardSwipedEvent(sessionId: 's1', cardId: 'c0', liked: true),
      );
      await _settle();

      expect(repository.session.status, SessionStatus.finished);
      expect(repository.session.winner?.cardId, 'c0');
      expect(repository.session.winner?.type, WinnerType.unanimous);
      for (final bloc in [host, guest]) {
        final state = bloc.currentState;
        expect(state, isA<SessionWonState>());
        expect((state as SessionWonState).winnerCard.id, 'c0');
      }
    });

    test('the closest match is declared once everyone has finished', () async {
      final repository = _FakeSessionRepository(
        _session(participants: {'host', 'guest'}),
      );
      final host = _bloc(repository, 'host');
      final guest = _bloc(repository, 'guest');
      await _settle();

      // Nobody agrees: one Yes each on c0, c1 and c3. c3 has the best rating.
      const hostLikes = {'c0', 'c3'};
      const guestLikes = {'c1'};
      for (final card in _cards) {
        host.add(
          CardSwipedEvent(
            sessionId: 's1',
            cardId: card.id,
            liked: hostLikes.contains(card.id),
          ),
        );
        guest.add(
          CardSwipedEvent(
            sessionId: 's1',
            cardId: card.id,
            liked: guestLikes.contains(card.id),
          ),
        );
        await _settle();
      }

      expect(repository.session.winner?.cardId, 'c3');
      expect(repository.session.winner?.type, WinnerType.closest);
      expect(guest.currentState, isA<SessionWonState>());
    });

    test('rejoining after voting on every card marks you finished', () async {
      final repository = _FakeSessionRepository(
        _session(
          participants: {'host', 'guest'},
          votes: {
            for (final card in _cards) card.id: {'host': false, 'guest': false},
          },
          finished: {'host'},
        ),
      );
      final guest = _bloc(repository, 'guest');
      await _settle();

      expect(repository.finishedCalls, ['guest']);
      expect(guest.currentState, isA<SessionWaitingState>());
    });

    test('rejoining resumes on the first card you have not voted on', () async {
      final repository = _FakeSessionRepository(
        _session(
          participants: {'host', 'guest'},
          votes: {
            for (final id in ['c0', 'c2', 'c3', 'c4']) id: {'guest': false},
          },
        ),
      );
      final guest = _bloc(repository, 'guest');
      await _settle();

      final state = guest.currentState;
      expect(state, isA<SessionSwipingState>());
      expect((state as SessionSwipingState).currentIndex, 1);
      expect(repository.finishedCalls, isEmpty);
    });

    test('a winner that cannot be saved is reported, not swallowed', () async {
      final repository = _FakeSessionRepository(
        _session(
          participants: {'host'},
          votes: {
            for (final card in _cards) card.id: {'host': false},
          },
          finished: {'host'},
        ),
      )..declareError = const LgtmSessionException('permission-denied');
      final host = _bloc(repository, 'host');
      await _settle();

      expect(host.currentState, isA<SessionErrorState>());
      expect(repository.declareCalls, 1);
    });
  });

  group('the votes decide the winner', () {
    test('a unanimous Yes wins before anyone has finished', () {
      final winner = _session(
        participants: {'host', 'guest'},
        votes: {
          'c2': {'host': true, 'guest': true},
        },
      ).decidedWinner;

      expect(winner?.cardId, 'c2');
      expect(winner?.type, WinnerType.unanimous);
    });

    test('without agreement nothing is decided until everyone finishes', () {
      final votes = {
        'c0': {'host': true, 'guest': false},
        'c3': {'host': false, 'guest': true},
      };

      expect(
        _session(participants: {'host', 'guest'}, votes: votes).decidedWinner,
        isNull,
      );
      final closest = _session(
        participants: {'host', 'guest'},
        votes: votes,
        finished: {'host', 'guest'},
      ).decidedWinner;
      expect(closest?.cardId, 'c3');
      expect(closest?.type, WinnerType.closest);
    });

    test('finishing counts only the people who joined the lobby', () {
      final session = _session(
        participants: {'host', 'guest'},
        finished: {'host', 'stranger'},
      );

      expect(session.allParticipantsFinished, isFalse);
    });

    test('the next card is the first one you have not voted on', () {
      final partway = _session(
        participants: {'guest'},
        votes: {
          'c0': {'guest': true},
          'c2': {'guest': false},
        },
      );
      final done = _session(
        participants: {'guest'},
        votes: {
          for (final card in _cards) card.id: {'guest': false},
        },
      );

      expect(partway.nextCardIndexFor('guest'), 1);
      expect(done.nextCardIndexFor('guest'), -1);
    });
  });

  group('members who have finished see live standings', () {
    test('each card shows its Yes votes and how many have voted on it', () {
      final standings = _session(
        participants: {'host', 'guest', 'third'},
        votes: {
          'c0': {'host': true, 'guest': true},
          'c3': {'guest': true, 'third': false},
        },
      ).standings;
      OptionStanding of(String id) =>
          standings.firstWhere((standing) => standing.card.id == id);

      expect(standings, hasLength(_cards.length));
      expect((of('c0').yesCount, of('c0').votedCount), (2, 2));
      expect((of('c3').yesCount, of('c3').votedCount), (1, 2));
      expect((of('c4').yesCount, of('c4').votedCount), (0, 0));
    });

    test('once the votes have decided, the top standing is the card the host '
        'confirms', () {
      const two = {'host', 'guest'};
      const three = {'host', 'guest', 'third'};
      final cases =
          <
            (
              Set<String>,
              Set<String>,
              List<OptionCard>,
              Map<String, Map<String, bool>>,
            )
          >[
            // Everyone finished, a clear leader.
            (
              two,
              two,
              _cards,
              {
                'c2': {'host': true, 'guest': false},
              },
            ),
            // Everyone finished, tied on Yes: the higher rating leads.
            (
              two,
              two,
              _cards,
              {
                'c0': {'host': true},
                'c3': {'guest': true},
              },
            ),
            // Everyone finished, tied on Yes and rating: the earlier card.
            (
              two,
              two,
              const [
                PlaceCard(id: 'a', title: 'First', imageUrl: '', rating: 4.0),
                PlaceCard(id: 'b', title: 'Second', imageUrl: '', rating: 4.0),
              ],
              {
                'b': {'host': true},
                'a': {'guest': true},
              },
            ),
            // Unanimous while one person is still swiping, next to a card
            // that has every Yes it has had so far.
            (
              three,
              {'host', 'guest'},
              _cards,
              {
                'c2': {'host': true, 'guest': true, 'third': true},
                'c3': {'host': true, 'guest': true},
              },
            ),
            // Two unanimous cards piled up while the host was away: the one
            // the host declares leads, even though Dim Sum rates higher.
            (
              two,
              {'guest'},
              _cards,
              {
                'c0': {'host': true, 'guest': true},
                'c3': {'host': true, 'guest': true},
              },
            ),
          ];

      for (final (participants, finished, cards, votes) in cases) {
        final session = _session(
          participants: participants,
          votes: votes,
          finished: finished,
          cards: cards,
        );
        expect(session.decidedWinner, isNotNull);
        expect(session.standings.first.card.id, session.decidedWinner?.cardId);
      }
    });

    testWidgets('a member who has finished sees the live standings', (
      tester,
    ) async {
      final repository = _FakeSessionRepository(
        _session(
          participants: {'host', 'guest', 'third'},
          votes: {
            'c0': {'guest': true, 'host': true},
            'c1': {'guest': false},
            'c2': {'guest': false},
            'c3': {'guest': true},
            'c4': {'guest': false},
          },
          finished: {'guest'},
        ),
      );
      final guest = _bloc(repository, 'guest');
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          home: SwipeScreen(
            args: SwipeArgs(groupId: 'g1', sessionId: 's1', bloc: guest),
          ),
        ),
      );

      expect(find.text('Live Standings'), findsOneWidget);
      expect(find.text('Waiting on 2... (1/3 finished)'), findsOneWidget);
      expect(find.text('2/3 YES'), findsOneWidget);
      expect(find.text('1/3 YES'), findsOneWidget);
      expect(find.text('0/3 YES'), findsNWidgets(3));
      expect(
        find.bySemanticsLabel(RegExp(r'Taqueria, 2 of 3 said yes$')),
        findsOneWidget,
      );
      expect(repository.finishedCalls, isEmpty);
    });
  });
}

const _cards = <OptionCard>[
  PlaceCard(id: 'c0', title: 'Taqueria', imageUrl: '', rating: 4.0),
  PlaceCard(id: 'c1', title: 'Ramen Bar', imageUrl: '', rating: 4.1),
  PlaceCard(id: 'c2', title: 'Pizzeria', imageUrl: '', rating: 3.0),
  PlaceCard(id: 'c3', title: 'Dim Sum', imageUrl: '', rating: 4.8),
  PlaceCard(id: 'c4', title: 'Diner', imageUrl: '', rating: 3.5),
];

LgtmSession _session({
  required Set<String> participants,
  Map<String, Map<String, bool>> votes = const {},
  Set<String> finished = const {},
  List<OptionCard> cards = _cards,
}) => LgtmSession(
  id: 's1',
  groupId: 'g1',
  hostId: 'host',
  category: SessionCategory.food,
  status: SessionStatus.active,
  createdAt: 0,
  cards: cards,
  participantIds: participants,
  votes: votes,
  finishedIds: finished,
);

SessionBloc _bloc(_FakeSessionRepository repository, String uid) {
  final bloc = SessionBloc(repository: repository, currentUserId: uid)
    ..add(const RejoinSessionEvent(sessionId: 's1'));
  addTearDown(bloc.dispose);
  return bloc;
}

/// Lets the echoes, acks and bloc handlers all run.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 40));

/// An in-memory stand in for the Realtime Database.
///
/// Like Firebase, every write raises the local `onValue` echo straight away
/// and completes its future only once the "server" acknowledges it a moment
/// later, which is the ordering the bloc has to cope with.
class _FakeSessionRepository implements LgtmSessionRepository {
  _FakeSessionRepository(this.session);

  LgtmSession session;
  final finishedCalls = <String>[];
  int declareCalls = 0;
  Object? declareError;

  final _listeners = <StreamController<LgtmSession?>>[];

  void _write(LgtmSession next) {
    session = next;
    for (final listener in [..._listeners]) {
      listener.add(next);
    }
  }

  Future<void> _ack() => Future<void>.delayed(const Duration(milliseconds: 2));

  @override
  Future<String?> activeSessionId(String groupId) async =>
      session.isFinished ? null : session.id;

  @override
  Future<LgtmSession> createSession({
    required String groupId,
    required String hostId,
    required SessionCategory category,
    required List<OptionCard> cards,
    double radiusMiles = 5.0,
  }) => throw UnimplementedError();

  @override
  Future<LgtmSession?> fetchSession(String sessionId) async => session;

  @override
  Stream<LgtmSession?> watchSession(String sessionId) {
    late final StreamController<LgtmSession?> controller;
    controller = StreamController<LgtmSession?>(
      onListen: () {
        controller.add(session);
        _listeners.add(controller);
      },
      onCancel: () => _listeners.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<void> joinLobby({
    required String sessionId,
    required String userId,
  }) async {}

  @override
  Future<void> beginSwiping({required String sessionId}) async {
    _write(session.copyWith(status: SessionStatus.active));
    await _ack();
  }

  @override
  Future<void> submitVote({
    required String sessionId,
    required String cardId,
    required String userId,
    required bool liked,
  }) async {
    _write(
      session.copyWith(
        votes: {
          ...session.votes,
          cardId: {...?session.votes[cardId], userId: liked},
        },
      ),
    );
    await _ack();
  }

  @override
  Future<void> markUserFinished({
    required String sessionId,
    required String userId,
  }) async {
    finishedCalls.add(userId);
    _write(session.copyWith(finishedIds: {...session.finishedIds, userId}));
    await _ack();
  }

  @override
  Future<SessionWinner?> checkAndDeclareWinner({
    required String sessionId,
    required LgtmSession session,
  }) async {
    final winner = session.decidedWinner;
    if (winner == null) return null;

    declareCalls++;
    final error = declareError;
    if (error != null) throw error;
    // `winner` can only be written once, as the database rules enforce.
    if (this.session.winner != null) {
      throw const LgtmSessionException('permission-denied');
    }
    _write(
      this.session.copyWith(status: SessionStatus.finished, winner: winner),
    );
    await _ack();
    return winner;
  }
}
