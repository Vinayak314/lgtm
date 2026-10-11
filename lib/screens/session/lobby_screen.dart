import 'package:flutter/material.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_top_bar.dart';
import 'swipe_screen.dart';

/// Arguments for the lobby screen.
class LobbyArgs {
  const LobbyArgs({
    required this.groupId,
    this.sessionId = '',
    this.category = 'food',
    this.bloc,
  });

  final String groupId;
  final String sessionId;
  final String category;
  final SessionBloc? bloc;

  static LobbyArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! LobbyArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, this.args});

  final LobbyArgs? args;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final bloc = widget.args?.bloc;
    if (bloc == null) {
      return const Scaffold(
        body: Center(child: Text('This session is unavailable.')),
      );
    }
    return StreamBuilder<SessionState>(
      stream: bloc.stateStream,
      initialData: bloc.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? bloc.currentState;
        if (state is SessionSwipingState) {
          return _transitionToSwipe(state);
        }
        if (state is SessionWonState) {
          return _transitionToSwipeForWinner(state);
        }
        return Scaffold(
          backgroundColor: LgtmColors.bg,
          body: Column(
            children: [
              LgtmTopBar(
                leading: LgtmIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  color: LgtmColors.primary,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                center: Text(
                  'Lobby',
                  style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
                ),
              ),
              Expanded(child: _content(state)),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(LgtmLayout.gutterTight),
            child: LgtmPrimaryButton(
              label: 'Begin',
              icon: Icons.play_arrow_rounded,
              height: 56,
              shadows: LgtmShadow.primarySoft,
              onPressed: state is SessionLobbyState && state.isHost
                  ? () =>
                        bloc.add(BeginSwipingEvent(sessionId: state.session.id))
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _content(SessionState state) {
    if (state is SessionLoadingState) {
      return Center(child: Text(state.message));
    }
    if (state is SessionErrorState) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(LgtmLayout.gutter),
          child: Text(state.errorMessage, textAlign: TextAlign.center),
        ),
      );
    }
    if (state is SessionLobbyState) {
      return Center(
        child: Text(
          '${state.session.participantIds.length} participant'
          '${state.session.participantIds.length == 1 ? '' : 's'} joined.',
        ),
      );
    }
    if (state is SessionWaitingState) {
      return Center(
        child: Text(
          'The session has started.\n'
          'Waiting for the group: '
          '${state.finishedCount}/${state.totalParticipants}',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state is SessionWonState) {
      return Center(
        child: Text(
          'The group has already selected ${state.winnerCard.title}.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return const Center(child: Text('Connecting to the session...'));
  }

  Widget _transitionToSwipe(SessionSwipingState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        LgtmRoutes.sessionSwipe,
        arguments: SwipeArgs(
          groupId: state.session.groupId,
          sessionId: state.session.id,
          category: state.session.category.wire,
          bloc: widget.args!.bloc,
        ),
      );
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  Widget _transitionToSwipeForWinner(SessionWonState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        LgtmRoutes.sessionSwipe,
        arguments: SwipeArgs(
          groupId: state.session.groupId,
          sessionId: state.session.id,
          category: state.session.category.wire,
          bloc: widget.args!.bloc,
        ),
      );
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
