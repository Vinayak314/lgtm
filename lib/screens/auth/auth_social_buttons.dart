import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_buttons.dart';

/// Google sign-in button shared by Login and Sign Up.
class LgtmSocialButtons extends StatelessWidget {
  const LgtmSocialButtons({
    super.key,
    required this.onGooglePressed,
    this.isLoading = false,
  });

  final VoidCallback onGooglePressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          label: isLoading
              ? 'Signing in with Google...'
              : 'Continue with Google',
          mark: const _GoogleMark(),
          onPressed: isLoading ? null : onGooglePressed,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.mark,
    required this.onPressed,
  });

  final String label;
  final Widget mark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return LgtmSecondaryButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 20, child: Center(child: mark)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LgtmSans.button.copyWith(color: LgtmColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stand-in for the Google mark: the bold letterform, as in the mockup. Swap
/// for the real brand asset when one is supplied.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: LgtmSans.title.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: LgtmColors.ink,
      ),
    );
  }
}
