import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_bottom_nav.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_top_bar.dart';
import 'result_screen.dart';

/// No Consensus Fallback (design.md §7): ranked list of top options with
/// vote counts and progress bars. The "FINALIZE DECISION" button navigates
/// to the Match screen for the top-voted option.
class NoConsensusScreen extends StatelessWidget {
  const NoConsensusScreen({super.key});

  // Mock ranked options until real session data is wired.
  static const _ranked = [
    _RankedOption(
      rank: 'I',
      name: 'Spicy Basil Thai',
      votesText: '6/8 VOTED',
      voteCountColor: LgtmColors.green,
      barColor: LgtmColors.barGreyGreen,
      barPercent: 0.75,
      dimmed: false,
    ),
    _RankedOption(
      rank: '2',
      name: 'Taco Heaven',
      votesText: '3/8 VOTED',
      voteCountColor: LgtmColors.green,
      barColor: LgtmColors.barGreyGreen,
      barPercent: 0.375,
      dimmed: false,
    ),
    _RankedOption(
      rank: '3',
      name: 'Burger Joint',
      votesText: '2/8 VOTED',
      voteCountColor: LgtmColors.roseSoft,
      barColor: LgtmColors.roseBar,
      barPercent: 0.25,
      dimmed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Stack(
        children: [
          // Decorative blob (design.md §0: small, x 0-100, y 64-100).
          Positioned(
            left: -30,
            top: 56,
            child: _Blob(width: 130, height: 55, color: const Color(0xFFEFECE8)),
          ),
          // Green blob peeking from the left (design.md §0).
          Positioned(
            left: -54,
            top: 215,
            child: _Blob(
              width: 60,
              height: 64,
              color: LgtmColors.green.withValues(alpha: 0.15),
            ),
          ),
          Column(
            children: [
              LgtmTopBar(
                leading: LgtmIconButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Back',
                  color: LgtmColors.primary,
                  size: 28,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                center: Text(
                  'LGTM',
                  style: LgtmSerif.logo.copyWith(
                    color: LgtmColors.primary,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LgtmLayout.gutterTight,
                    vertical: 8,
                  ),
                  children: [
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        'Closest Match!',
                        style: LgtmSerif.display.copyWith(
                          color: LgtmColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "Couldn't reach 100%. Here are the top\noptions based on group votes:",
                        textAlign: TextAlign.center,
                        style: LgtmSans.body.copyWith(
                          color: LgtmColors.inkMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    for (final option in _ranked) ...[
                      _RankedRow(option: option),
                      const SizedBox(height: 13),
                    ],
                    const SizedBox(height: 40),
                    LgtmPrimaryButton(
                      label: 'FINALIZE DECISION',
                      height: 60,
                      shadows: LgtmShadow.primarySoft,
                      labelStyle: LgtmSans.title.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          LgtmRoutes.sessionResult,
                          arguments: ResultArgs(
                            winnerName: _ranked.first.name,
                            rating: 4.5,
                            priceLevel: '\$\$',
                            distance: '1.2 MI',
                            isUnanimous: false,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: LgtmBottomNav(
        activeTab: LgtmNavTab.matches,
        onSelect: (tab) {},
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ranked row (design.md §7)
// ---------------------------------------------------------------------------

class _RankedOption {
  const _RankedOption({
    required this.rank,
    required this.name,
    required this.votesText,
    required this.voteCountColor,
    required this.barColor,
    required this.barPercent,
    required this.dimmed,
  });

  final String rank;
  final String name;
  final String votesText;
  final Color voteCountColor;
  final Color barColor;
  final double barPercent;
  final bool dimmed;
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({required this.option});

  final _RankedOption option;

  @override
  Widget build(BuildContext context) {
    final opacity = option.dimmed ? 0.7 : 1.0;
    final nameColor = option.dimmed ? LgtmColors.inkFaint : LgtmColors.ink;

    return Opacity(
      opacity: opacity,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: LgtmColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(33)),
          border: Border.all(color: LgtmColors.rankedRowBorder),
        ),
        child: Stack(
          children: [
            // Progress bar along the bottom edge.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(33),
                  bottomRight: Radius.circular(33),
                ),
                child: SizedBox(
                  height: 3,
                  child: FractionallySizedBox(
                    widthFactor: option.barPercent,
                    alignment: Alignment.centerLeft,
                    child: ColoredBox(color: option.barColor),
                  ),
                ),
              ),
            ),
            // Row content.
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    option.rank,
                    style: LgtmSerif.body.copyWith(
                      color: nameColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Thumbnail placeholder.
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LgtmColors.photoFallbackTop,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LgtmSans.title.copyWith(color: nameColor),
                  ),
                ),
                // Vote badge.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: LgtmColors.bg,
                    borderRadius: LgtmRadius.pill,
                    border: Border.all(color: LgtmColors.voteBadgeBorder),
                  ),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: option.votesText.split(' ').first,
                        style: LgtmSans.caption.copyWith(
                          color: option.voteCountColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: ' VOTED',
                        style: LgtmSans.caption.copyWith(
                          color: LgtmColors.inkSoft,
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative blob
// ---------------------------------------------------------------------------

class _Blob extends StatelessWidget {
  const _Blob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.9,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(55),
              topRight: Radius.circular(38),
              bottomLeft: Radius.circular(45),
              bottomRight: Radius.circular(52),
            ),
          ),
        ),
      ),
    );
  }
}
