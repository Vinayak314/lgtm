import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Constrains the app to the 390pt design column and centres it on wider
/// screens (desktop, tablets, landscape). Everything outside the column keeps
/// the cream background, exactly like the mockup.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.child,
    this.backgroundColor = LgtmColors.bg,
    this.align = Alignment.topCenter,
  });

  final Widget child;
  final Color backgroundColor;
  final AlignmentGeometry align;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LgtmLayout.designWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Applies the standard 24pt side padding used by most screens.
class Gutter extends StatelessWidget {
  const Gutter({
    super.key,
    required this.child,
    this.width = LgtmLayout.gutter,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width),
      child: child,
    );
  }
}

/// Reserves the same top space the top bars use for screens that have no
/// header (Login, Match): `max(safe-area-inset-top, 20pt)`, so their content
/// also clears the phone status bar.
class LgtmStatusBarInset extends StatelessWidget {
  const LgtmStatusBarInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: LgtmLayout.topInset(context)),
      child: child,
    );
  }
}
