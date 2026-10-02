import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// The shared loading state: a crimson spinner with an optional plain language
/// label underneath. Used while a screen waits on data or on a submission.
class LgtmLoadingState extends StatelessWidget {
  const LgtmLoadingState({super.key, this.label, this.compact = false});

  /// Plain language explanation, e.g. "Checking your groups...". Omit for a
  /// bare spinner.
  final String? label;

  /// Drops the surrounding breathing room, for use inside a card or a button.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox.square(
      dimension: compact ? 20 : 28,
      child: const CircularProgressIndicator(strokeWidth: 2.5),
    );

    final text = label == null
        ? null
        : Text(
            label!,
            textAlign: TextAlign.center,
            style: LgtmSans.bodySmall.copyWith(color: LgtmColors.inkMuted),
          );

    return Semantics(
      label: label ?? 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LgtmLayout.gutter,
              vertical: compact ? 4 : 24,
            ),
            child: text == null
                ? spinner
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [spinner, const SizedBox(height: 16), text],
                  ),
          ),
        ),
      ),
    );
  }
}
