import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Generic fully rounded chip used for tags, ratings and status text.
class LgtmPill extends StatelessWidget {
  const LgtmPill({
    super.key,
    required this.child,
    this.height = 26,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.fill,
    this.borderColor,
    this.borderWidth = 1,
    this.width,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;
  final Color? fill;
  final Color? borderColor;
  final double borderWidth;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: LgtmRadius.pill,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// Rounded tile that holds a single green glyph. Used in the Past Winners rows
/// (36pt mint square, radius 12pt), as a circle on group list rows and
/// anywhere else a glyph needs its own surface.
///
/// The glyph is always centred and always leaves at least 8pt of tile on every
/// side: it can never fill or overflow the tile.
class LgtmIconTile extends StatelessWidget {
  const LgtmIconTile({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize = 20,
    this.fill = LgtmColors.mint,
    this.color = LgtmColors.green,
    this.borderRadius = LgtmRadius.tile,
  }) : assert(
         iconSize <= size - 16,
         'iconSize must leave at least 8pt of tile on every side',
       );

  final IconData icon;
  final double size;
  final double iconSize;
  final Color fill;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fill, borderRadius: borderRadius),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}
