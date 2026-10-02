import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// The "LGTM" wordmark. Vollkorn italic 700. Colour and size change per
/// screen, so both are parameters.
class LgtmLogo extends StatelessWidget {
  const LgtmLogo({
    super.key,
    this.size = 30,
    this.color = LgtmColors.primary,
    this.text = 'LGTM',
  });

  final double size;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'LGTM',
      child: ExcludeSemantics(
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: LgtmSerif.logo.copyWith(fontSize: size, color: color),
        ),
      ),
    );
  }
}
