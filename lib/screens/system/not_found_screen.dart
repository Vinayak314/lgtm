import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_logo.dart';

/// The screen for any path the app does not recognise, and for the screens
/// that have not been built yet. It names the path it could not resolve so a
/// broken deep link is obvious instead of mysterious.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.path});

  /// The route that was asked for, when there was one.
  final String? path;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final message = path == null
        ? 'That screen does not exist.'
        : 'There is nothing at "$path" yet.';

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: LgtmStatusBarInset(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LgtmLayout.gutter),
            child: Column(
              children: [
                const Spacer(),
                const LgtmLogo(size: 30),
                const SizedBox(height: 32),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check the link, or head back to the app.',
                  textAlign: TextAlign.center,
                  style: LgtmSans.bodySmall.copyWith(
                    color: LgtmColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 32),
                LgtmPrimaryButton(
                  label: 'Go to LGTM',
                  height: 48,
                  shadows: LgtmShadow.primarySoft,
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                        LgtmRoutes.splash,
                        (route) => false,
                      ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
