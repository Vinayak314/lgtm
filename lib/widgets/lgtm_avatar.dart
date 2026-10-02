import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Circular avatar with a real photo when one is available and a flat
/// fallback colour otherwise, plus the 2pt card coloured ring used in stacks.
class LgtmAvatar extends StatelessWidget {
  const LgtmAvatar({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.size = 40,
    this.fallbackColor = const Color(0xFF4A4A4A),
    this.ringColor,
    this.ringWidth = 0,
    this.label,
  });

  final String? imagePath;
  final String? imageUrl;
  final double size;
  final Color fallbackColor;
  final Color? ringColor;
  final double ringWidth;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final photo = imagePath != null
        ? Image.asset(
            imagePath!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : imageUrl != null
        ? Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();

    Widget avatar = ClipOval(
      child: SizedBox(width: size, height: size, child: photo),
    );

    if (ringColor != null && ringWidth > 0) {
      avatar = Container(
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
        child: avatar,
      );
    }

    if (label == null) return avatar;
    return Semantics(label: label, image: true, child: avatar);
  }

  Widget _fallback() => ColoredBox(
    color: fallbackColor,
    child: SizedBox(width: size, height: size),
  );
}

/// Overlapping avatar stack: circles 38pt with a 6pt overlap and a 2pt ring.
class LgtmAvatarStack extends StatelessWidget {
  const LgtmAvatarStack({
    super.key,
    required this.avatars,
    this.size = 38,
    this.overlap = 6,
    this.ringColor = LgtmColors.card,
  });

  final List<Widget> avatars;
  final double size;
  final double overlap;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 4,
      child: Stack(
        children: [
          for (var i = 0; i < avatars.length; i++)
            Positioned(left: i * (size - overlap), child: avatars[i]),
        ],
      ),
    );
  }
}
