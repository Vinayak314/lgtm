import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Arguments for the lobby screen.
class LobbyArgs {
  const LobbyArgs({
    required this.groupId,
    this.sessionId = '',
    this.category = 'food',
  });

  final String groupId;
  final String sessionId;
  final String category;

  static LobbyArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! LobbyArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

/// Session lobby. Participant data is shown only after a live session is wired.
class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key, this.args});

  final LobbyArgs? args;

  @override
  Widget build(BuildContext context) => Scaffold(
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
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(LgtmLayout.gutter),
              child: Text(
                'Live session details are not available yet.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(LgtmLayout.gutterTight),
      child: LgtmPrimaryButton(
        label: 'Begin',
        icon: Icons.play_arrow_rounded,
        height: 56,
        shadows: LgtmShadow.primarySoft,
        onPressed: null,
      ),
    ),
  );
}
