import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_buttons.dart';

enum LgtmAuthProvider { google, apple }

/// The two stacked social buttons from the Login design: greige fill, 2pt
/// mauve outline, 8pt radius, 56pt tall.
///
/// Nothing is wired to Google or Apple yet, that arrives with the backend, so
/// a tap says so plainly instead of pretending to sign anybody in.
class LgtmSocialButtons extends StatelessWidget {
  const LgtmSocialButtons({super.key, this.onProviderTapped});

  /// Called with the provider that was tapped. Defaults to telling the person
  /// it is not connected yet.
  final ValueChanged<LgtmAuthProvider>? onProviderTapped;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          mark: const _GoogleMark(),
          onPressed: () => _tapped(context, LgtmAuthProvider.google),
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Continue with Apple',
          mark: Icon(Icons.apple, size: 17, color: LgtmColors.ink),
          onPressed: () => _tapped(context, LgtmAuthProvider.apple),
        ),
      ],
    );
  }

  void _tapped(BuildContext context, LgtmAuthProvider provider) {
    final handler = onProviderTapped;
    if (handler != null) {
      handler(provider);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${provider == LgtmAuthProvider.google ? 'Google' : 'Apple'} sign in '
          'is not connected yet.',
        ),
      ),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LgtmSecondaryButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 20, child: Center(child: mark)),
          const SizedBox(width: 8),
          Text(label, style: LgtmSans.button.copyWith(color: LgtmColors.ink)),
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
