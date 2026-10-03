import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Shared top app bar pattern: 64pt of content sitting below a top inset of
/// `max(safe-area-inset-top, 20pt)`, cream background, 1pt bottom rule at the
/// very bottom of the header, 1pt bottom border, 12pt side padding, 24pt
/// glyphs.
///
/// The bar is a three column grid: 48pt leading, the title, 48pt trailing.
/// Both side cells are the same width whether or not they hold anything, so
/// the title is centred on the whole screen rather than on the space the
/// leading button leaves behind.
///
/// Place it as the first child of the screen body. It reserves its own status
/// bar space, so it must not also be handed to `Scaffold.appBar`, which adds
/// that space itself.
class LgtmTopBar extends StatelessWidget {
  const LgtmTopBar({
    super.key,
    this.leading,
    this.center,
    this.actions = const [],
    this.centerTitle = true,
    this.showDivider = true,
    this.backgroundColor = LgtmColors.bg,
  });

  final Widget? leading;
  final Widget? center;

  /// Trailing controls. The trailing cell is one 48pt wide so the title stays
  /// centred, which means a screen passes at most one (a "..." menu, an
  /// avatar). Anything wider would push the title off centre.
  final List<Widget> actions;
  final bool centerTitle;
  final bool showDivider;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: LgtmLayout.topInset(context)),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showDivider
            ? const Border(bottom: BorderSide(color: LgtmColors.headerBorder))
            : null,
      ),
      child: SizedBox(
        height: LgtmLayout.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: _sideWidth,
                child: Center(child: leading ?? const SizedBox.shrink()),
              ),
              Expanded(
                child: center == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: centerTitle
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: center,
                      ),
              ),
              SizedBox(
                width: _sideWidth,
                child: Center(
                  child: switch (actions) {
                    [] => const SizedBox.shrink(),
                    [final single] => single,
                    _ => Row(mainAxisSize: MainAxisSize.min, children: actions),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Width of the leading and trailing cells. Equal on both sides, which is
  /// what puts the title on the true centre line.
  static const _sideWidth = 48.0;
}

/// Square icon button sized for the 64pt top bar.
class LgtmIconButton extends StatelessWidget {
  const LgtmIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 24,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: size, color: color),
          ),
        ),
      ),
    );
  }
}

/// The standard hamburger menu button: three rounded horizontal lines, 24pt
/// wide, 2pt stroke, in `--ink-muted`. The glyph is left aligned inside the
/// 44pt tap target so it sits exactly 24pt from the screen edge, while the
/// touch area stays a comfortable 44pt.
class LgtmMenuButton extends StatelessWidget {
  const LgtmMenuButton({
    super.key,
    required this.onPressed,
    this.color = LgtmColors.inkMuted,
    this.size = 24,
    this.strokeWidth = 2,
    this.tooltip = 'Open menu',
  });

  final VoidCallback onPressed;
  final Color color;
  final double size;
  final double strokeWidth;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  painter: _HamburgerPainter(
                    color: color,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HamburgerPainter extends CustomPainter {
  const _HamburgerPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Keep the stroke inside the box and space the three lines evenly.
    final inset = strokeWidth / 2;
    final gap = (size.height - 3 * strokeWidth) / 4;

    for (final y in [inset + gap, size.height / 2, size.height - inset - gap]) {
      canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HamburgerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
