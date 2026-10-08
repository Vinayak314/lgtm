import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../models/option_card.dart';
import '../models/session.dart';

/// Full-screen freeze overlay shown the instant a winner is declared.
///
/// Prevents further swipes and displays a celebratory badge before navigating
/// to the match screen.
class WinnerOverlay extends StatelessWidget {
  const WinnerOverlay({
    super.key,
    required this.winnerCard,
    required this.winnerType,
    required this.onContinue,
  });

  final OptionCard winnerCard;
  final WinnerType winnerType;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isUnanimous = winnerType == WinnerType.unanimous;

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LgtmColors.card,
            borderRadius: LgtmRadius.cardXL,
            boxShadow: LgtmShadow.inkHard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: LgtmColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isUnanimous ? "IT'S A MATCH!" : 'CLOSEST MATCH!',
                style: LgtmSerif.display.copyWith(
                  color: LgtmColors.ink,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                winnerCard.title,
                textAlign: TextAlign.center,
                style: LgtmSans.title.copyWith(
                  color: LgtmColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LgtmColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: LgtmRadius.card,
                  ),
                ),
                child: const Text('SEE RESULTS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
