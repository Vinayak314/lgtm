import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_bottom_nav.dart';
import '../../widgets/lgtm_top_bar.dart';

/// Arguments for the swipe screen.
class SwipeArgs {
  const SwipeArgs({required this.groupId, this.category = 'food'});

  final String groupId;
  final String category;

  static SwipeArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! SwipeArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

/// The Active Swipe screen (design.md §5).
///
/// Greyer paper background, status pill, swipe card deck, accept/reject
/// buttons. Uses mock food data for now; will wire to the session BLoC later.
class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key, this.args});

  final SwipeArgs? args;

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  double _dragRotation = 0;
  final bool _frozen = false;

  late final AnimationController _resetController;
  late Animation<Offset> _resetOffsetAnimation;
  late Animation<double> _resetRotationAnimation;

  // Mock deck until real API data is wired.
  static const _mockCards = [
    _MockSwipeCard(
      title: 'Spicy Basil Thai',
      distance: '1.2 miles away',
      rating: 4.5,
      tags: ['Thai', '\$\$', 'Spicy'],
    ),
    _MockSwipeCard(
      title: 'Taco Heaven',
      distance: '0.8 miles away',
      rating: 4.2,
      tags: ['Mexican', '\$', 'Casual'],
    ),
    _MockSwipeCard(
      title: 'Sushi Zen',
      distance: '2.1 miles away',
      rating: 4.8,
      tags: ['Japanese', '\$\$\$', 'Fine Dining'],
    ),
    _MockSwipeCard(
      title: 'Burger Joint',
      distance: '0.5 miles away',
      rating: 4.0,
      tags: ['American', '\$', 'Fast Food'],
    ),
    _MockSwipeCard(
      title: 'Pasta Palace',
      distance: '1.5 miles away',
      rating: 4.3,
      tags: ['Italian', '\$\$', 'Cozy'],
    ),
  ];

  static const _mockMovieCards = [
    _MockSwipeCard(
      title: 'Interstellar',
      distance: '2h 49m',
      rating: 8.7,
      tags: ['Sci-Fi', 'Adventure'],
    ),
    _MockSwipeCard(
      title: 'The Grand Budapest Hotel',
      distance: '1h 39m',
      rating: 8.1,
      tags: ['Comedy', 'Drama'],
    ),
    _MockSwipeCard(
      title: 'Spider-Man: Into the Spider-Verse',
      distance: '1h 57m',
      rating: 8.4,
      tags: ['Animation', 'Action'],
    ),
    _MockSwipeCard(
      title: 'Knives Out',
      distance: '2h 10m',
      rating: 7.9,
      tags: ['Mystery', 'Comedy'],
    ),
    _MockSwipeCard(
      title: 'Arrival',
      distance: '1h 56m',
      rating: 7.9,
      tags: ['Sci-Fi', 'Drama'],
    ),
  ];

  List<_MockSwipeCard> get _cards =>
      widget.args?.category == 'movies' ? _mockMovieCards : _mockCards;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetOffsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOut,
    ));
    _resetRotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetController.addListener(() {
      setState(() {
        _dragOffset = _resetOffsetAnimation.value;
        _dragRotation = _resetRotationAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  bool get _deckExhausted => _currentIndex >= _cards.length;

  void _advanceCard() {
    if (_frozen || _deckExhausted) return;
    final finished = _currentIndex + 1 >= _cards.length;
    setState(() {
      _dragOffset = Offset.zero;
      _dragRotation = 0;
      _currentIndex++;
    });
    if (finished && mounted) {
      Navigator.of(context).pushReplacementNamed(LgtmRoutes.sessionWaiting);
    }
  }

  void _onSwipeEnd(DismissDirection direction) {
    _advanceCard();
  }

  void _onButtonSwipe({required bool liked}) {
    if (_frozen || _deckExhausted) return;
    final direction = liked ? 1.0 : -1.0;
    setState(() {
      _dragOffset = Offset(400 * direction, 0);
      _dragRotation = 0.3 * direction;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _advanceCard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _deckExhausted ? null : _cards[_currentIndex];

    return Scaffold(
      backgroundColor: LgtmColors.bgPaper,
      body: Column(
        children: [
          Container(
            color: LgtmColors.bg,
            child: LgtmTopBar(
              backgroundColor: LgtmColors.bg,
              leading: LgtmMenuButton(
                onPressed: () {},
                color: LgtmColors.primary,
              ),
              center: Text(
                'LGTM',
                style: LgtmSerif.logo.copyWith(color: LgtmColors.ink),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Status pill.
          _StatusPill(
            current: _currentIndex + 1,
            total: _cards.length,
            membersText: '3/4 members swiping',
          ),
          const SizedBox(height: 14),
          // Card stack or exhausted state.
          Expanded(
            child: card != null
                ? _SwipeArea(
                    card: card,
                    index: _currentIndex,
                    total: _cards.length,
                    dragOffset: _dragOffset,
                    dragRotation: _dragRotation,
                    frozen: _frozen,
                    onDragUpdate: (details) {
                      if (_frozen) return;
                      setState(() {
                        _dragOffset += details.delta;
                        _dragRotation = _dragOffset.dx / 800;
                      });
                    },
                    onDragEnd: (details) {
                      if (_frozen) return;
                      if (_dragOffset.dx.abs() > 100) {
                        _onSwipeEnd(
                          _dragOffset.dx > 0
                              ? DismissDirection.startToEnd
                              : DismissDirection.endToStart,
                        );
                      } else {
                        _resetOffsetAnimation = Tween<Offset>(
                          begin: _dragOffset,
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _resetController,
                          curve: Curves.easeOut,
                        ));
                        _resetRotationAnimation = Tween<double>(
                          begin: _dragRotation,
                          end: 0,
                        ).animate(CurvedAnimation(
                          parent: _resetController,
                          curve: Curves.easeOut,
                        ));
                        _resetController.forward(from: 0);
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: LgtmColors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All cards swiped!',
                          style: LgtmSerif.display.copyWith(
                            color: LgtmColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Waiting for others to finish...',
                          style: LgtmSans.body.copyWith(
                            color: LgtmColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (!_deckExhausted) ...[
            const SizedBox(height: 20),
            _ActionButtons(
              onReject: () => _onButtonSwipe(liked: false),
              onAccept: () => _onButtonSwipe(liked: true),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
      bottomNavigationBar: LgtmBottomNav(
        activeTab: LgtmNavTab.swipe,
        onSelect: (tab) {
          if (tab == LgtmNavTab.groups) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              LgtmRoutes.groups,
              (_) => false,
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status pill
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.current,
    required this.total,
    required this.membersText,
  });

  final int current;
  final int total;
  final String membersText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: LgtmColors.pillFill,
        borderRadius: LgtmRadius.pill,
        border: Border.all(color: LgtmColors.roseBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: LgtmColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Waiting on 1... ($membersText)',
            style: LgtmSans.caption.copyWith(
              color: LgtmColors.inkOnPaper,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe card area with drag physics
// ---------------------------------------------------------------------------

class _SwipeArea extends StatelessWidget {
  const _SwipeArea({
    required this.card,
    required this.index,
    required this.total,
    required this.dragOffset,
    required this.dragRotation,
    required this.frozen,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final _MockSwipeCard card;
  final int index;
  final int total;
  final Offset dragOffset;
  final double dragRotation;
  final bool frozen;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: Center(
        child: Transform.translate(
          offset: dragOffset,
          child: Transform.rotate(
            angle: dragRotation,
            child: _SwipeCardWidget(card: card, index: index, total: total),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe card visual (design.md §5)
// ---------------------------------------------------------------------------

class _SwipeCardWidget extends StatelessWidget {
  const _SwipeCardWidget({
    required this.card,
    required this.index,
    required this.total,
  });

  final _MockSwipeCard card;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 356,
      height: 572,
      decoration: BoxDecoration(
        // Asymmetric radius per design.md §5.
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(56),
        ),
        // Dark fallback gradient until real images are wired.
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LgtmColors.photoFallbackTop,
            LgtmColors.photoFallbackBottom,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Bottom gradient overlay.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(56),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: const Alignment(0, -0.1),
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Card content.
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        card.title,
                        style: LgtmSerif.display.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    _RatingChip(rating: card.rating),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      card.distance,
                      style: LgtmSans.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final tag in card.tags) _TagChip(label: tag),
                  ],
                ),
              ],
            ),
          ),
          // Progress indicator.
          Positioned(
            top: 16,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: LgtmRadius.pill,
              ),
              child: Text(
                '${index + 1} / $total',
                style: LgtmSans.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: LgtmRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 13, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: LgtmSans.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: LgtmColors.tagFill.withValues(alpha: 0.85),
        borderRadius: LgtmRadius.pill,
      ),
      child: Center(
        child: Text(
          label,
          style: LgtmSans.caption.copyWith(
            color: LgtmColors.tagInk,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accept / Reject buttons (design.md §5)
// ---------------------------------------------------------------------------

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.onReject, required this.onAccept});

  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reject: 64px circle.
        GestureDetector(
          onTap: onReject,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: LgtmColors.rejectFill,
              shape: BoxShape.circle,
              border: Border.all(color: LgtmColors.rejectBorder, width: 1.5),
              boxShadow: LgtmShadow.rejectHard,
            ),
            child: const Icon(Icons.close, size: 28, color: LgtmColors.reject),
          ),
        ),
        const SizedBox(width: 24),
        // Accept: 80px circle.
        GestureDetector(
          onTap: onAccept,
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: LgtmColors.greenDeep,
              shape: BoxShape.circle,
              boxShadow: LgtmShadow.acceptHard,
            ),
            child: const Icon(Icons.check, size: 36, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

class _MockSwipeCard {
  const _MockSwipeCard({
    required this.title,
    required this.distance,
    required this.rating,
    required this.tags,
  });

  final String title;
  final String distance;
  final double rating;
  final List<String> tags;
}
