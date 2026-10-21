import 'package:flutter/material.dart';

import '../../blocs/session/session_state.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_pill.dart';
import '../../widgets/lgtm_standing_row.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Waiting screen: shown once you have swiped your whole deck, with live
/// standings while the rest of the group finishes and the host confirms.
///
/// Standings only appear after your own deck is done, so the tally can never
/// sway how you vote.
class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key, this.state});

  /// The live session. Null when the route is opened without one.
  final SessionWaitingState? state;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            center: Text(
              'LGTM',
              style: LgtmSerif.logo.copyWith(color: LgtmColors.primary),
            ),
          ),
          Expanded(
            child: state == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(LgtmLayout.gutter),
                      child: Text(
                        'Session progress is not available yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _Standings(state: state),
          ),
        ],
      ),
    );
  }
}

class _Standings extends StatelessWidget {
  const _Standings({required this.state});

  final SessionWaitingState state;

  @override
  Widget build(BuildContext context) {
    final total = state.totalParticipants;
    final finished = state.finishedCount;
    final everyoneDone = state.session.allParticipantsFinished;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LgtmLayout.gutterTight,
        16,
        LgtmLayout.gutterTight,
        LgtmLayout.gutter,
      ),
      children: [
        Center(
          child: LgtmPill(
            height: 30,
            fill: LgtmColors.pillFill,
            borderColor: LgtmColors.roseBorder,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: LgtmColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  everyoneDone
                      ? 'Everyone is done ($total/$total)'
                      : 'Waiting on ${total - finished}... '
                            '($finished/$total finished)',
                  style: LgtmSans.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: LgtmColors.inkOnPaper,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Live Standings',
          textAlign: TextAlign.center,
          style: LgtmSerif.display.copyWith(color: LgtmColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          // A unanimous card has already won, even if somebody is still
          // swiping, so only the host's confirmation is left.
          state.session.decidedWinner != null
              ? 'Waiting for the host to confirm the top pick.'
              : 'These can change until everyone finishes swiping.',
          textAlign: TextAlign.center,
          style: LgtmSans.body.copyWith(color: LgtmColors.inkMuted),
        ),
        const SizedBox(height: 24),
        for (final (index, standing) in state.session.standings.indexed) ...[
          LgtmStandingRow(
            rank: index + 1,
            title: standing.card.title,
            imageUrl: standing.card.imageUrl,
            yesCount: standing.yesCount,
            total: total,
            isLeader: index == 0 && standing.yesCount > 0,
          ),
          const SizedBox(height: 13),
        ],
      ],
    );
  }
}
