import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// The shared empty/error skeleton: an icon tile, a serif title, a plain
/// language explanation and one optional action, centred in whatever space it
/// is given. Shared by [LgtmEmptyState] and [LgtmErrorState] so the two can
/// never drift apart.
class LgtmCenteredState extends StatelessWidget {
  const LgtmCenteredState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.iconFill = LgtmColors.surface,
    this.iconColor = LgtmColors.inkSoft,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color iconFill;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LgtmLayout.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconFill,
                borderRadius: LgtmRadius.tile,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LgtmSans.body.copyWith(color: LgtmColors.inkMuted),
            ),
            if (action case final a?) ...[const SizedBox(height: 24), a],
          ],
        ),
      ),
    );
  }
}
