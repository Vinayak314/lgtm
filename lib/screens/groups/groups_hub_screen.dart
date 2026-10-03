import 'package:flutter/material.dart';

import '../../app/groups_store.dart';
import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_avatar.dart';
import '../../widgets/lgtm_bottom_nav.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_card.dart';
import '../../widgets/lgtm_logo.dart';
import '../../widgets/lgtm_pill.dart';
import '../../widgets/lgtm_top_bar.dart';
import '../../widgets/lgtm_winner_row.dart';
import '../../widgets/states/lgtm_empty_state.dart';
import '../../widgets/states/lgtm_loading_state.dart';

/// My Groups, the signed in landing page.
///
/// The first group gets the full card with its members and past winners, the
/// rest get the compact row from the design. Create and Join sit under the
/// Start Session CTA.
class GroupsHubScreen extends StatefulWidget {
  const GroupsHubScreen({super.key});

  @override
  State<GroupsHubScreen> createState() => _GroupsHubScreenState();
}

class _GroupsHubScreenState extends State<GroupsHubScreen> {
  bool _loadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadRequested) return;
    _loadRequested = true;
    LgtmGroupsScope.read(context).load();
  }

  void _openCreate() => Navigator.of(context).pushNamed(LgtmRoutes.createGroup);

  void _openJoin() => Navigator.of(context).pushNamed(LgtmRoutes.joinGroup);

  void _openGroup(LgtmGroup group) => Navigator.of(context).pushNamed(
    LgtmRoutes.groupDetail,
    arguments: GroupDetailArgs(groupId: group.id),
  );

  /// Groups and Profile are built. Swipe and Matches belong to the session
  /// items in TODO.md, so they say so instead of going nowhere.
  void _onTab(LgtmNavTab tab) {
    switch (tab) {
      case LgtmNavTab.groups:
        return;
      case LgtmNavTab.swipe:
        _say('The swipe flow is not built yet.');
      case LgtmNavTab.matches:
        _say('Matches are not built yet.');
      case LgtmNavTab.profile:
        Navigator.of(context).pushNamed(LgtmRoutes.profile);
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final store = LgtmGroupsScope.of(context);

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            leading: LgtmMenuButton(
              onPressed: () => _say('The menu is not built yet.'),
            ),
            center: const LgtmLogo(size: 30, color: LgtmColors.primary),
            actions: [
              LgtmAvatar(
                size: 40,
                fallbackColor: const Color(0xFF4A4A4A),
                label: 'Your profile',
                onTap: () =>
                    Navigator.of(context).pushNamed(LgtmRoutes.profile),
              ),
            ],
          ),
          Expanded(child: _body(store)),
        ],
      ),
      bottomNavigationBar: LgtmBottomNav(
        activeTab: LgtmNavTab.groups,
        onSelect: _onTab,
      ),
    );
  }

  Widget _body(LgtmGroupsStore store) {
    if (!store.isReady) {
      return const LgtmLoadingState(label: 'Loading your groups...');
    }

    final groups = store.groups;
    if (groups.isEmpty) {
      return LgtmEmptyState(
        title: 'No groups yet',
        message:
            'Create a group for your squad, or join one with a code, and '
            'start deciding together.',
        actionLabel: 'Create Group',
        onAction: _openCreate,
      );
    }

    final first = groups.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
      children: [
        Semantics(
          header: true,
          child: Text(
            'My Groups',
            style: LgtmSerif.display.copyWith(color: LgtmColors.ink),
          ),
        ),
        const SizedBox(height: 24),
        _FullGroupCard(group: first, onTap: () => _openGroup(first)),
        for (final group in groups.skip(1)) ...[
          const SizedBox(height: 24),
          _CompactGroupCard(group: group, onTap: () => _openGroup(group)),
        ],
        const SizedBox(height: 36),
        LgtmPrimaryButton(
          label: 'Start New Session (Dinner)',
          icon: Icons.add_circle_outline,
          height: 60,
          shadows: LgtmShadow.primarySoft,
          onPressed: () => _say('Session setup is not built yet.'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_circle_outline,
                label: 'Create Group',
                onPressed: _openCreate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.login,
                label: 'Join by Code',
                onPressed: _openJoin,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The tall card: members, then past winners.
class _FullGroupCard extends StatelessWidget {
  const _FullGroupCard({required this.group, required this.onTap});

  final LgtmGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = LgtmSans.label.copyWith(color: LgtmColors.inkMuted);
    final winners = group.recentWinners;

    return LgtmCard(
      radius: LgtmRadius.cardXL,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LgtmCardHeader(
            title: group.name,
            icon: groupIcon(group.kind),
            iconColor: LgtmColors.green,
          ),
          const SizedBox(height: 24),
          Text('ACTIVE MEMBERS', style: labelStyle),
          const SizedBox(height: 12),
          LgtmAvatarStack(
            avatars: [
              for (final member in group.members)
                LgtmAvatar(
                  size: 38,
                  fallbackColor: member.avatarColor,
                  ringColor: LgtmColors.card,
                  ringWidth: 2,
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: LgtmColors.divider),
          const SizedBox(height: 24),
          Text('PAST WINNERS', style: labelStyle),
          if (!group.hasWinners) ...[
            const SizedBox(height: 16),
            Text(
              'No wins yet. Start a session and the first one lands here.',
              style: LgtmSans.bodySmall.copyWith(color: LgtmColors.inkSoft),
            ),
          ] else
            for (final session in winners) ...[
              const SizedBox(height: 16),
              LgtmWinnerRow(
                icon: session.winnerIcon,
                label: session.winnerName,
              ),
            ],
        ],
      ),
    );
  }
}

/// The 72pt pill row used for every group after the first.
class _CompactGroupCard extends StatelessWidget {
  const _CompactGroupCard({required this.group, required this.onTap});

  final LgtmGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LgtmCard(
      height: 72,
      radius: LgtmRadius.pill,
      padding: const EdgeInsets.only(left: 16, right: 20),
      fill: LgtmColors.cardPure,
      onTap: onTap,
      child: Row(
        children: [
          LgtmIconTile(
            icon: groupIcon(group.kind),
            size: 40,
            iconSize: 20,
            fill: LgtmColors.tileCircle,
            borderRadius: LgtmRadius.pill,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LgtmSerif.title.copyWith(
                fontSize: 20,
                color: LgtmColors.ink,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: LgtmColors.ink),
        ],
      ),
    );
  }
}

/// Create and Join under the CTA: the same greige button as the rest of the
/// app, with an icon and a label.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return LgtmSecondaryButton(
      onPressed: onPressed,
      height: 52,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: LgtmColors.ink),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LgtmSans.button.copyWith(color: LgtmColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one icon per group kind, kept in the UI layer so the model stays free
/// of icons.
IconData groupIcon(LgtmGroupKind kind) => switch (kind) {
  LgtmGroupKind.home => Icons.home,
  LgtmGroupKind.work => Icons.dns_outlined,
};
