import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Shown when you finish swiping before the rest of the group.
///
/// Live "3 of 4 finished" progress, a message, and a subtle animation to
/// show the app is still working.
class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  // Mock values until the session BLoC is wired.
  final int _finishedCount = 3;
  final int _totalCount = 4;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated dots.
                  AnimatedBuilder(
                    animation: _bounce,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final delay = i * 0.2;
                          final t = ((_bounce.value + delay) % 1.0);
                          final y = -8 * (1 - (2 * t - 1).abs());
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Transform.translate(
                              offset: Offset(0, y),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: LgtmColors.primary
                                      .withValues(alpha: 0.5 + 0.5 * t),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Waiting for others...',
                    style: LgtmSerif.display.copyWith(color: LgtmColors.ink),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_finishedCount of $_totalCount finished',
                    style: LgtmSans.body.copyWith(
                      color: LgtmColors.inkMuted,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Progress bar.
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: LgtmRadius.pill,
                      child: LinearProgressIndicator(
                        value: _finishedCount / _totalCount,
                        backgroundColor: LgtmColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          LgtmColors.green,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'You finished your deck.',
                    style: LgtmSans.bodySmall.copyWith(
                      color: LgtmColors.inkSoft,
                    ),
                  ),
                  Text(
                    'Results will appear once everyone is done.',
                    style: LgtmSans.bodySmall.copyWith(
                      color: LgtmColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
