import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Results screen shown once a live session has ranked its options.
class NoConsensusScreen extends StatelessWidget {
  const NoConsensusScreen({super.key});

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
                'Results will appear when a live session is complete.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
