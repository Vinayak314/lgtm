import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Arguments for the swipe screen.
class SwipeArgs {
  const SwipeArgs({required this.groupId, this.category = 'food'});

  final String groupId;
  final String category;

  static SwipeArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! SwipeArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

/// Swipe screen. Cards will appear when a live session provides its options.
class SwipeScreen extends StatelessWidget {
  const SwipeScreen({super.key, this.args});

  final SwipeArgs? args;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: LgtmColors.bgPaper,
    appBar: AppBar(title: const Text('Swipe')),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(LgtmLayout.gutter),
        child: Text(
          'No options are available. Start a live session to load options.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
