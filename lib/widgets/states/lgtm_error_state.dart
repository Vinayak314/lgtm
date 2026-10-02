import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../lgtm_buttons.dart';
import 'lgtm_centered_state.dart';

/// The shared error state: what went wrong in plain language, plus the action
/// that fixes it. Always give it a [onRetry] so the screen is never a dead
/// end.
class LgtmErrorState extends StatelessWidget {
  const LgtmErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.icon = Icons.error_outline,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LgtmCenteredState(
      icon: icon,
      iconFill: LgtmColors.rejectFill,
      iconColor: LgtmColors.reject,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : LgtmPrimaryButton(
              label: retryLabel,
              onPressed: onRetry,
              height: 48,
              expand: false,
              shadows: LgtmShadow.primarySoft,
            ),
    );
  }
}
