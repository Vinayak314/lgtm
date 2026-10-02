import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// The shared soft rounded card: near white cream fill, 1pt rose border.
class LgtmCard extends StatelessWidget {
  const LgtmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LgtmLayout.gutter),
    this.radius = LgtmRadius.card,
    this.fill = LgtmColors.card,
    this.borderColor = LgtmColors.roseBorder,
    this.borderWidth = 1,
    this.shadows,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Header row shared by cards: a leading icon tile, a serif title and an
/// optional trailing widget.
class LgtmCardHeader extends StatelessWidget {
  const LgtmCardHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor = LgtmColors.primary,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon case final i?) ...[
          Icon(i, size: 24, color: iconColor),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
