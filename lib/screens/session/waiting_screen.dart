import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Waiting screen, populated when live session progress is available.
class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: LgtmColors.bg,
    body: Column(
      children: [
        LgtmTopBar(
          center: Text(
            'LGTM',
            style: LgtmSerif.logo.copyWith(color: LgtmColors.primary),
          ),
        ),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(LgtmLayout.gutter),
              child: Text(
                'Session progress is not available yet.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
