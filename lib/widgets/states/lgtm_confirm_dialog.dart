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
      actionsPadding: const EdgeInsets.fromLTRB(
        LgtmLayout.gutter,
        0,
        LgtmLayout.gutter,
        LgtmLayout.gutter,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LgtmPrimaryButton(
                label: confirmLabel,
                height: 48,
                fill: destructive ? LgtmColors.reject : LgtmColors.primary,
                onPressed: () => Navigator.of(context).pop(true),
                shadows: destructive
                    ? LgtmShadow.rejectHard
                    : LgtmShadow.primarySoft,
                labelStyle: LgtmSerif.cta,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
