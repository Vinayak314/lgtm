import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import 'lgtm_pill.dart';

/// One option on the live leaderboard, styled as the ranked row from
/// design.md section 7: rank, thumbnail, name, a `2/3 YES` badge and a bar
/// along the bottom showing how close the option is to everyone agreeing.
class LgtmStandingRow extends StatelessWidget {
  const LgtmStandingRow({
    super.key,
    required this.rank,
    required this.title,
    required this.imageUrl,
    required this.yesCount,
    required this.total,
    this.isLeader = false,
  });

  final int rank;
  final String title;
  final String imageUrl;
  final int yesCount;

  /// Participants in the session, the most Yes votes an option can get.
  final int total;

  /// Whether this row currently leads, drawn with a crimson border.
  final bool isLeader;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : (yesCount / total).clamp(0.0, 1.0);
    final hasSupport = yesCount > 0;
    final ink = hasSupport ? LgtmColors.ink : LgtmColors.inkFaint;

    return Semantics(
      label: 'Rank $rank, $title, $yesCount of $total said yes',
      excludeSemantics: true,
      child: Opacity(
        opacity: hasSupport ? 1 : 0.7,
        child: Container(
          height: 65,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: LgtmColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(33)),
            border: Border.all(
              color: isLeader ? LgtmColors.primary : LgtmColors.rankedRowBorder,
              width: isLeader ? 1.5 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        // design.md shows the leader as a Roman "I".
                        rank == 1 ? 'I' : '$rank',
                        style: LgtmSerif.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Thumbnail(imageUrl: imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LgtmSans.title.copyWith(color: ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LgtmPill(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      fill: LgtmColors.bg,
                      borderColor: LgtmColors.voteBadgeBorder,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$yesCount/$total',
                              style: LgtmSans.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: hasSupport
                                    ? LgtmColors.green
                                    : LgtmColors.roseSoft,
                              ),
                            ),
                            TextSpan(
                              text: ' YES',
                              style: LgtmSans.label.copyWith(
                                fontSize: 11,
                                letterSpacing: 0.5,
                                color: LgtmColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: share,
                  child: ColoredBox(
                    color: hasSupport
                        ? LgtmColors.barGreyGreen
                        : LgtmColors.roseBar,
                    child: const SizedBox(height: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 40pt circular photo, or the dark photo fallback when there is none.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LgtmColors.photoFallbackTop, LgtmColors.photoFallbackBottom],
        ),
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: 40,
        child: imageUrl.isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}
