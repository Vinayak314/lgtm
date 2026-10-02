import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

enum LgtmNavTab { groups, swipe, matches, profile }

/// ONE shared bottom navigation. Built once, never restyled per screen.
///
/// Filled icons, crimson bold active label (15pt), muted grey brown inactive
/// labels (13pt). No pill, no background, no underline on the active item.
class LgtmBottomNav extends StatelessWidget {
  const LgtmBottomNav({
    super.key,
    required this.activeTab,
    required this.onSelect,
  });

  final LgtmNavTab activeTab;
  final ValueChanged<LgtmNavTab> onSelect;

  static const _items = <(LgtmNavTab, String, IconData)>[
    (LgtmNavTab.groups, 'Groups', Icons.groups),
    (LgtmNavTab.swipe, 'Swipe', Icons.style),
    (LgtmNavTab.matches, 'Matches', Icons.star),
    (LgtmNavTab.profile, 'Profile', Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomInset),
      decoration: const BoxDecoration(
        color: LgtmColors.bg,
        boxShadow: LgtmShadow.navSoft,
      ),
      child: Row(
        children: [
          for (final (tab, label, icon) in _items)
            Expanded(
              child: _NavItem(
                tab: tab,
                label: label,
                icon: icon,
                active: tab == activeTab,
                onTap: () => onSelect(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final LgtmNavTab tab;
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? LgtmColors.primary : LgtmColors.inkSoft;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: LgtmRadius.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavIcon(tab: tab, icon: icon, color: color),
              const SizedBox(height: 8),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: (active ? LgtmSans.navActive : LgtmSans.navInactive)
                      .copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled 26pt glyphs. The Swipe tab uses a tilted playing card drawn by hand
/// so it matches the mockup rather than a generic Material icon.
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.tab, required this.icon, required this.color});

  final LgtmNavTab tab;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (tab == LgtmNavTab.swipe) {
      return Transform.rotate(
        angle: 0.26,
        child: CustomPaint(
          size: const Size.square(26),
          painter: _SwipeCardPainter(color),
        ),
      );
    }
    return Icon(icon, size: 26, color: color);
  }
}

class _SwipeCardPainter extends CustomPainter {
  const _SwipeCardPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 1, size.width - 6, size.height - 4),
      const Radius.circular(3),
    );
    canvas.drawRRect(card, paint);
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.24),
      1.6,
      Paint()..color = LgtmColors.bg,
    );
  }

  @override
  bool shouldRepaint(_SwipeCardPainter oldDelegate) =>
      oldDelegate.color != color;
}
