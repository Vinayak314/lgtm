import 'package:flutter/material.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';
import '../../app/router.dart';
import '../../app/groups_store.dart';
import '../../core/design_tokens.dart';
import '../../models/session.dart';

class SwipeArgs {
  const SwipeArgs({
    required this.groupId,
    this.category = 'food',
    this.sessionId = '',
    this.bloc,
  });

  final String groupId;
  final String category;
  final String sessionId;
  final SessionBloc? bloc;

  static SwipeArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! SwipeArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key, this.args});

  final SwipeArgs? args;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  bool _voteInFlight = false;

  @override
  void dispose() {
    // Do NOT dispose the bloc here. It is shared via route arguments and
    // may be reused if the user navigates back and re-enters the session.
    // The bloc will be collected when no widget holds a reference to it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.args?.bloc;
    if (bloc == null) {
      return const Scaffold(body: Center(child: Text('Session unavailable.')));
    }
    return StreamBuilder<SessionState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? bloc.currentState;
        if (state is SessionSwipingState && state.cards.isNotEmpty) {
          final card = state.cards[state.currentIndex];
          return Scaffold(
            backgroundColor: LgtmColors.bgPaper,
            appBar: AppBar(title: const Text('Swipe')),
            body: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(LgtmLayout.gutter),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.network(
                              card.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              '${card.title}\n${card.subtitle}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontSize: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(LgtmLayout.gutter),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _voteInFlight
                              ? null
                              : () => _vote(bloc, card.id, false),
                          icon: const Icon(Icons.close),
                          label: const Text('Pass'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _voteInFlight
                              ? null
                              : () => _vote(bloc, card.id, true),
                          icon: const Icon(Icons.favorite),
                          label: const Text('Like'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (state is SessionWaitingState) {
          return Scaffold(
            body: Center(
              child: Text(
                'Waiting for the group: '
                '${state.finishedCount}/${state.totalParticipants}',
              ),
            ),
          );
        }
        if (state is SessionWonState) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Match')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(LgtmLayout.gutter),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.celebration,
                      size: 64,
                      color: LgtmColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.winnerType == WinnerType.unanimous
                          ? 'Everyone chose this!'
                          : 'Closest match',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.winnerCard.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        final store = LgtmGroupsScope.read(context);
                        store.refresh().whenComplete(() {
                          if (!mounted) return;
                          Navigator.of(context).popUntil(
                            (route) =>
                                route.settings.name == LgtmRoutes.groupDetail,
                          );
                        });
                      },
                      child: const Text('Back to group'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (state is SessionErrorState) {
          return Scaffold(body: Center(child: Text(state.errorMessage)));
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Future<void> _vote(SessionBloc bloc, String cardId, bool liked) async {
    final args = widget.args;
    if (args == null) return;
    setState(() => _voteInFlight = true);
    bloc.add(
      CardSwipedEvent(sessionId: args.sessionId, cardId: cardId, liked: liked),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _voteInFlight = false);
  }
}
