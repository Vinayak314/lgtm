import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../widgets/lgtm_avatar.dart';
import '../../widgets/lgtm_bottom_nav.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_card.dart';
import '../../widgets/lgtm_logo.dart';
import '../../widgets/lgtm_pill.dart';
import '../../widgets/lgtm_top_bar.dart';
import '../../widgets/lgtm_winner_row.dart';

/// Temporary screen used to review the shared design system before the real
/// screens land. Replaced by the named routes in the routing step.
class FoundationPreviewScreen extends StatefulWidget {
  const FoundationPreviewScreen({super.key});

  @override
  State<FoundationPreviewScreen> createState() =>
      _FoundationPreviewScreenState();
}

class _FoundationPreviewScreenState extends State<FoundationPreviewScreen> {
  LgtmNavTab _tab = LgtmNavTab.groups;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          const LgtmTopBar(
            leading: LgtmMenuButton(onPressed: _noop),
            center: LgtmLogo(size: 30),
            actions: [LgtmAvatar(size: 40, fallbackColor: Color(0xFF4A4A4A))],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
              children: [
                Text(
                  'My Groups',
                  style: LgtmSerif.display.copyWith(color: LgtmColors.ink),
                ),
                const SizedBox(height: 24),
                const LgtmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LgtmCardHeader(
                        title: 'Roommates',
                        icon: Icons.home,
                        iconColor: LgtmColors.green,
                      ),
                      SizedBox(height: 24),
                      Text('ACTIVE MEMBERS', style: LgtmSans.label),
                      SizedBox(height: 12),
                      LgtmAvatarStack(
                        avatars: [
                          LgtmAvatar(
                            size: 38,
                            fallbackColor: Color(0xFF4A4A4A),
                            ringColor: LgtmColors.card,
                            ringWidth: 2,
                          ),
                          LgtmAvatar(
                            size: 38,
                            fallbackColor: Color(0xFF2F5D5B),
                            ringColor: LgtmColors.card,
                            ringWidth: 2,
                          ),
                          LgtmAvatar(
                            size: 38,
                            fallbackColor: Color(0xFF4B3F63),
                            ringColor: LgtmColors.card,
                            ringWidth: 2,
                          ),
                          LgtmAvatar(
                            size: 38,
                            fallbackColor: Color(0xFF5B4A3A),
                            ringColor: LgtmColors.card,
                            ringWidth: 2,
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Divider(color: LgtmColors.divider),
                      SizedBox(height: 24),
                      Text('PAST WINNERS', style: LgtmSans.label),
                      SizedBox(height: 24),
                      LgtmWinnerRow(
                        icon: Icons.lunch_dining,
                        label: 'Taco Bell',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                LgtmPrimaryButton(
                  label: 'Start New Session (Dinner)',
                  onPressed: () {},
                  icon: Icons.add_circle_outline,
                  shadows: LgtmShadow.primarySoft,
                ),
                const SizedBox(height: 24),
                const LgtmCard(
                  height: 96,
                  radius: LgtmRadius.pill,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      LgtmIconTile(
                        icon: Icons.dns_outlined,
                        size: 48,
                        iconSize: 22,
                        fill: LgtmColors.tileCircle,
                        borderRadius: LgtmRadius.pill,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Hackathon Squad',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: LgtmSerif.family,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: LgtmColors.ink),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Secondary', style: LgtmSerif.title),
                const SizedBox(height: 12),
                const LgtmSecondaryButton(
                  onPressed: null,
                  child: Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: LgtmSans.family,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LgtmPill(
                      fill: LgtmColors.primarySoft,
                      borderColor: LgtmColors.primary,
                      borderWidth: 2,
                      child: Text(
                        'FOOD  ✓',
                        style: TextStyle(
                          fontFamily: LgtmSans.family,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: LgtmColors.primary,
                        ),
                      ),
                    ),
                    LgtmPill(
                      fill: LgtmColors.surface,
                      child: Text(
                        'MOVIES',
                        style: TextStyle(
                          fontFamily: LgtmSans.family,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: LgtmColors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: LgtmBottomNav(
        activeTab: _tab,
        onSelect: (t) => setState(() => _tab = t),
      ),
    );
  }
}
