import 'package:flutter/material.dart';

import '../app/demo_mode.dart';
import '../core/design_tokens.dart';
import 'lgtm_card.dart';
import 'lgtm_pill.dart';

/// The card that tells a demo build's user what to type, and fills it in when
/// they tap it.
///
/// It only ever appears in a demo build: the mock behind it accepts any
/// credentials, so nobody should have to guess the pair that was picked.
class LgtmDemoHint extends StatelessWidget {
  const LgtmDemoHint({super.key, required this.onUse});

  /// Called with the credentials to fill the form with.
  final void Function(String email, String password) onUse;

  @override
  Widget build(BuildContext context) {
    return LgtmCard(
      padding: const EdgeInsets.all(16),
      fill: LgtmColors.mint,
      borderColor: LgtmColors.green,
      onTap: _fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LgtmIconTile(
                icon: Icons.science_outlined,
                size: 28,
                iconSize: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Demo mode',
                  style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
                ),
              ),
              LgtmPill(
                height: 28,
                fill: LgtmColors.green,
                child: Text(
                  'Fill it in',
                  style: LgtmSans.button.copyWith(color: LgtmColors.cardPure),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing is saved and no network is used. Any password works.',
            style: LgtmSans.bodySmall.copyWith(color: LgtmColors.ink),
          ),
          const SizedBox(height: 10),
          // The pair itself, so it can be read off the screen and typed by hand
          // as easily as tapped.
          _credential('Email', demoEmail),
          _credential('Password', demoPassword),
        ],
      ),
    );
  }

  void _fill() => onUse(demoEmail, demoPassword);

  Widget _credential(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: RichText(
      text: TextSpan(
        style: LgtmSans.bodySmall.copyWith(color: LgtmColors.ink),
        children: [
          TextSpan(
            text: '$label  ',
            style: LgtmSans.caption.copyWith(color: LgtmColors.green),
          ),
          TextSpan(
            text: value,
            style: LgtmSans.button.copyWith(color: LgtmColors.ink),
          ),
        ],
      ),
    ),
  );
}
