import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// The centred title and subtitle that open the Create and Join forms.
class LgtmFormHeader extends StatelessWidget {
  const LgtmFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.topSpacing = 48,
  });

  final String title;
  final String subtitle;

  /// Space between the top bar and the title.
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: LgtmSerif.display.copyWith(color: LgtmColors.ink),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 350,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: LgtmSans.body.copyWith(color: LgtmColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
