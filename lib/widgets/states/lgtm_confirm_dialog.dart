import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../lgtm_buttons.dart';

/// The shared confirmation state for decisions that are annoying to undo:
/// leaving a group, signing out, discarding a session.
///
/// Always resolves to a bool, never throws: dismissing the dialog counts as
/// "no", so the caller never has to handle a null.
abstract final class LgtmConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return confirmed ?? false;
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      // 12 between the title and the body. The space down to the buttons is the
      // theme's actions padding, so every dialog keeps the same rhythm.
      contentPadding: const EdgeInsets.fromLTRB(
        LgtmLayout.gutter,
        12,
        LgtmLayout.gutter,
        0,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Flexible so a long label or a large text scale shrinks the pair
            // rather than overflowing the dialog.
            Flexible(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: LgtmPrimaryButton(
                label: confirmLabel,
                height: 44,
                // Brand crimson either way, as the design has it, so the
                // destructive half only decides whether it carries a shadow.
                fill: LgtmColors.primary,
                onPressed: () => Navigator.of(context).pop(true),
                shadows: destructive ? const [] : LgtmShadow.primarySoft,
                labelStyle: LgtmSerif.cta.copyWith(fontSize: 16),
                expand: false,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
