import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/group_session.dart';
import '../../widgets/lgtm_top_bar.dart';
import '../../widgets/lgtm_winner_row.dart';
import '../../widgets/states/lgtm_empty_state.dart';

/// Arguments for the Session History screen.
class SessionHistoryArgs {
  const SessionHistoryArgs({
    required this.groupId,
    required this.groupName,
    this.pastSessions = const [],
  });

  final String groupId;
  final String groupName;
  final List<LgtmGroupSession> pastSessions;

  static SessionHistoryArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! SessionHistoryArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

/// Screen showing past group session decisions.
class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key, this.args});

  final SessionHistoryArgs? args;

  @override
  Widget build(BuildContext context) {
    final groupName = args?.groupName ?? 'Group';
    final sessions = args?.pastSessions ?? const <LgtmGroupSession>[];

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            leading: LgtmIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            center: Text(
              '$groupName History',
              style: LgtmSerif.title,
            ),
          ),
          Expanded(
            child: sessions.isEmpty
                ? const LgtmEmptyState(
                    title: 'No Past Decisions',
                    message:
                        'Start your first session to see unanimous and closest-match decisions recorded here.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: sessions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = sessions[index];
                      return LgtmWinnerRow(
                        icon: item.winnerIcon,
                        label: '${item.activity} • ${item.winnerName}',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
