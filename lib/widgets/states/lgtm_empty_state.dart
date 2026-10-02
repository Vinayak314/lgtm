import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../lgtm_buttons.dart';
import 'lgtm_centered_state.dart';

/// The shared empty state: there is genuinely nothing here yet, never an
/// error. Pair it with the action that fills the space.
class LgtmEmptyState extends StatelessWidget {
  const LgtmEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LgtmCenteredState(
      icon: icon,
      iconFill: LgtmColors.surface,
      iconColor: LgtmColors.inkSoft,
      title: title,
      message: message,
      action: onAction == null
          ? null
          : LgtmPrimaryButton(
              label: actionLabel ?? 'Get started',
              onPressed: onAction,
              height: 48,
              expand: false,
              shadows: LgtmShadow.primarySoft,
            ),
    );
  }
}
