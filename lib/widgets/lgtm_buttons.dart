import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

enum LgtmButtonShape { pill, square }

/// The shared CTA.
///
/// Crimson fill, white label. [shape] is a pill everywhere except Session
/// Setup and Login, which use the 8pt radius.
class LgtmPrimaryButton extends StatelessWidget {
  const LgtmPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.shape = LgtmButtonShape.pill,
    this.labelStyle,
    this.iconColor = Colors.white,
    this.iconSize = 20,
    this.fill = LgtmColors.primary,
    this.shadows,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final LgtmButtonShape shape;
  final TextStyle? labelStyle;
  final Color iconColor;
  final double iconSize;

  /// Fill colour. Defaults to crimson; destructive actions pass
  /// `LgtmColors.reject`.
  final Color fill;
  final List<BoxShadow>? shadows;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final radius = shape == LgtmButtonShape.pill
        ? LgtmRadius.pill
        : LgtmRadius.small;
    final enabled = onPressed != null;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon case final i?) ...[
          Icon(i, size: iconSize, color: iconColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: (labelStyle ?? LgtmSerif.cta).copyWith(color: Colors.white),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? fill : LgtmColors.surface2,
          borderRadius: radius,
          boxShadow: enabled ? shadows : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The shared secondary button: greige fill, 2pt mauve outline, 8pt radius.
class LgtmSecondaryButton extends StatelessWidget {
  const LgtmSecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 56,
    this.fill = LgtmColors.surface,
    this.borderColor = LgtmColors.borderMauve,
    this.borderWidth = 2,
    this.shadows = LgtmShadow.buttonTiny,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: LgtmRadius.small,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: onPressed == null ? null : shadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: LgtmRadius.small,
          child: SizedBox(
            height: height,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
