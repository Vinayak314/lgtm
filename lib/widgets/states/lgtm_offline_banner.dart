import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// The shared offline notice: a slim bar pinned under a top bar saying the
/// device has no connection and what the screen is showing instead. Never a
/// blocking dialog, because the cached data is still worth reading.
class LgtmOfflineBanner extends StatelessWidget {
  const LgtmOfflineBanner({
    super.key,
    this.message = "You're offline. Showing what we already have.",
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: LgtmColors.surface,
        padding: const EdgeInsets.fromLTRB(
          LgtmLayout.gutter,
          10,
          LgtmLayout.gutterTight,
          10,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: LgtmColors.divider)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: LgtmColors.inkMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: LgtmSans.caption.copyWith(color: LgtmColors.inkMuted),
                ),
              ),
              if (onRetry case final retry?) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: retry,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    retryLabel,
                    style: LgtmSans.button.copyWith(
                      color: LgtmColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
