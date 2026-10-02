import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import 'lgtm_pill.dart';

/// One past winner: a mint icon tile and the name, on a pill shaped row.
class LgtmWinnerRow extends StatelessWidget {
  const LgtmWinnerRow({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: LgtmColors.surface2,
        borderRadius: LgtmRadius.pill,
        border: Border.all(color: LgtmColors.winnerRowBorder),
      ),
      child: Row(
        children: [
          LgtmIconTile(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LgtmSans.title,
            ),
          ),
        ],
      ),
    );
  }
}
