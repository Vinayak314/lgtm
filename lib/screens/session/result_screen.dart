import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_buttons.dart';

/// Arguments for the result screen.
class ResultArgs {
  const ResultArgs({
    required this.winnerName,
    required this.rating,
    required this.priceLevel,
    required this.distance,
    this.isUnanimous = true,
  });

  final String winnerName;
  final double rating;
  final String priceLevel;
  final String distance;
  final bool isUnanimous;

  static ResultArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! ResultArgs) return null;
    return args;
  }
}

/// The Match Screen (design.md §6): celebration when everyone agrees.
///
/// Full cream background, no top bar, no bottom nav. Decorative circles,
/// match card with hard shadow, Get Directions and Share to Group Chat
/// buttons.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, this.args});

  final ResultArgs? args;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return const Scaffold(
        backgroundColor: LgtmColors.bg,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(LgtmLayout.gutter),
            child: Text('A session result is not available.'),
          ),
        ),
      );
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Stack(
        children: [
          // Decorative circles (design.md §6).
          Positioned(
            right: -2,
            top: 101 + topInset,
            child: _DecoCircle(size: 36, color: LgtmColors.sageDeco),
          ),
          Positioned(
            left: 186,
            top: 120 + topInset,
            child: _DecoCircle(size: 16, color: LgtmColors.sageDeco),
          ),
          Positioned(
            left: 212,
            top: 122 + topInset,
            child: _DecoCircle(size: 14, color: LgtmColors.mint),
          ),
          Positioned(
            left: 55,
            bottom: 30 + bottomInset,
            child: _DecoCircle(size: 40, color: LgtmColors.rose),
          ),
          Positioned(
            left: 80,
            bottom: 28 + bottomInset,
            child: _DecoCircle(size: 30, color: LgtmColors.mint),
          ),
          Positioned(
            right: 98,
            bottom: 54 + bottomInset,
            child: _DecoCircle(size: 24, color: LgtmColors.sageDeco),
          ),
          // Confetti particles.
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.sizeOf(context),
              painter: _ConfettiPainter(
                progress: _confettiController.value,
              ),
            ),
          ),
          // Main content.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  // Title.
                  Text(
                    "It's a Match!",
                    style: LgtmSerif.logo.copyWith(
                      color: LgtmColors.primary,
                      fontSize: 44,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    args.isUnanimous ? '100% Agreement' : 'Closest Match',
                    style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
                  ),
                  const SizedBox(height: 18),
                  // Match card with hard shadow.
                  _MatchCard(
                    name: args.winnerName,
                    rating: args.rating,
                    priceLevel: args.priceLevel,
                    distance: args.distance,
                  ),
                  const SizedBox(height: 16),
                  // Get Directions.
                  _DirectionsButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Directions coming soon.'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Share to Group Chat.
                  LgtmSecondaryButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share coming soon.'),
                        ),
                      );
                    },
                    height: 64,
                    borderColor: LgtmColors.borderMauve,
                    borderWidth: 1,
                    shadows: LgtmShadow.muveHard,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.share,
                          size: 24,
                          color: LgtmColors.ink,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share to Group Chat',
                          style: LgtmSans.body.copyWith(
                            color: LgtmColors.ink,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Match card (design.md §6)
// ---------------------------------------------------------------------------

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.name,
    required this.rating,
    required this.priceLevel,
    required this.distance,
  });

  final String name;
  final double rating;
  final String priceLevel;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358,
      height: 273,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LgtmColors.bg,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: const Color(0xFF3A2F2F)),
        boxShadow: LgtmShadow.inkHard,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fallback gradient.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LgtmColors.photoFallbackTop,
                    LgtmColors.photoFallbackBottom,
                  ],
                ),
              ),
            ),
            // Bottom gradient.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: const Alignment(0, -0.2),
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Text overlay.
            Positioned(
              left: 16,
              bottom: 16,
              right: 54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: LgtmSerif.display.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_outline,
                          size: 14, color: LgtmColors.star),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: _detailStyle),
                      _dot(),
                      Text(priceLevel, style: _detailStyle),
                      _dot(),
                      Text(distance, style: _detailStyle),
                    ],
                  ),
                ],
              ),
            ),
            // Check badge.
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: LgtmColors.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: LgtmColors.primary),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 22,
                  color: LgtmColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final _detailStyle = LgtmSans.caption.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text('•', style: _detailStyle),
  );
}

// ---------------------------------------------------------------------------
// Directions button (pill, hard shadow)
// ---------------------------------------------------------------------------

class _DirectionsButton extends StatelessWidget {
  const _DirectionsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358,
      height: 64,
      decoration: BoxDecoration(
        color: LgtmColors.primary,
        borderRadius: LgtmRadius.pill,
        boxShadow: LgtmShadow.primaryHard,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: LgtmRadius.pill,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.diamond_outlined,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Get Directions',
                style: LgtmSans.body.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative circles
// ---------------------------------------------------------------------------

class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lightweight confetti animation
// ---------------------------------------------------------------------------

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});

  final double progress;

  static final _particles = List.generate(40, (_) => _Particle());

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in _particles) {
      final x = p.x * size.width;
      final y = p.startY * size.height +
          progress * p.speed * size.height;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _Particle {
  static final _rng = math.Random(42);

  final double x = _rng.nextDouble();
  final double startY = -_rng.nextDouble() * 0.3;
  final double speed = 0.5 + _rng.nextDouble() * 0.8;
  final double radius = 2 + _rng.nextDouble() * 4;
  final Color color = [
    LgtmColors.primary,
    LgtmColors.green,
    LgtmColors.star,
    LgtmColors.mint,
    LgtmColors.rose,
    LgtmColors.sageDeco,
  ][_rng.nextInt(6)];
}
