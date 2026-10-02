import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// The shared readable error: an alert glyph plus a whole sentence, in the
/// reject colour. Used under form fields and above forms, so a problem always
/// looks the same and never reads as "Invalid input".
class LgtmInlineError extends StatelessWidget {
  const LgtmInlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 16, color: LgtmColors.reject),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: LgtmSans.caption.copyWith(
                color: LgtmColors.reject,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
