import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/groups_store.dart';
import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_avatar.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_card.dart';
import '../../widgets/lgtm_pill.dart';
import '../../widgets/lgtm_top_bar.dart';
import '../../widgets/states/lgtm_empty_state.dart';
import '../session/session_setup_screen.dart';

/// Group Detail: the invite link to share, who is in the group, what they
/// already decided, and the way into a new session.
class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.args});

  final GroupDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final store = LgtmGroupsScope.of(context);
    final group = store.groupById(args.groupId);
    if (group == null) {
      return Scaffold(
        backgroundColor: LgtmColors.bg,
        body: Column(
          children: [
            LgtmTopBar(
              leading: LgtmIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Back to My Groups',
                color: LgtmColors.primary,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: LgtmEmptyState(
                title: 'Group not found',
                message: 'That group is not on your account any more.',
                actionLabel: 'Go to My Groups',
                onAction: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(LgtmRoutes.groups, (_) => false),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            leading: LgtmIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back to My Groups',
              color: LgtmColors.primary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            center: Semantics(
              header: true,
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
              ),
            ),
          ),
          Expanded(child: _body(context, store, group)),
        ],
      ),
      bottomNavigationBar: _StartSessionBar(
        onPressed: () => Navigator.of(context).pushNamed(
          LgtmRoutes.sessionSetup,
          arguments: SessionSetupArgs(groupId: group.id),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, LgtmGroupsStore store, LgtmGroup group) {
    final labelStyle = LgtmSans.label.copyWith(color: LgtmColors.inkMuted);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LgtmLayout.gutterTight,
        24,
        LgtmLayout.gutterTight,
        24,
      ),
      children: [
        _InviteCard(
          group: group,
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: group.inviteLink));
            if (!context.mounted) return;
            _say(context, 'Invite link copied.');
          },
          onShare: () => _say(context, 'Sharing is not connected yet.'),
        ),
        const SizedBox(height: 24),
        Semantics(header: true, child: Text('MEMBERS', style: labelStyle)),
        const SizedBox(height: 12),
        LgtmCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < group.members.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(color: LgtmColors.divider),
                  ),
                _MemberRow(
                  member: group.members[i],
                  isYou: group.members[i].id == store.currentMember?.id,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text('PAST SESSIONS', style: labelStyle),
        ),
        const SizedBox(height: 12),
        if (!group.hasWinners)
          LgtmCard(
            child: Text(
              'No sessions yet. Start one and the result lands here.',
              style: LgtmSans.bodySmall.copyWith(color: LgtmColors.inkSoft),
            ),
          )
        else
          LgtmCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < group.sessions.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: LgtmColors.divider),
                    ),
                  _SessionRow(session: group.sessions[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Invite link on a mint pill, with copy and share.
class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.group,
    required this.onCopy,
    required this.onShare,
  });

  final LgtmGroup group;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return LgtmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LgtmCardHeader(
            title: 'Share Invite Link',
            icon: Icons.ios_share,
          ),
          const SizedBox(height: 12),
          Text(
            'Send this link to your squad to get them in instantly.',
            style: LgtmSans.body.copyWith(color: LgtmColors.inkMuted),
          ),
          const SizedBox(height: 16),
          Container(
            height: 53,
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: LgtmColors.mint,
              borderRadius: LgtmRadius.pill,
              border: Border.all(color: LgtmColors.mintBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.inviteLink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LgtmSans.button.copyWith(
                      color: LgtmColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _PillAction(
                  icon: Icons.content_copy,
                  tooltip: 'Copy invite link',
                  onPressed: onCopy,
                ),
                _PillAction(
                  icon: Icons.ios_share,
                  tooltip: 'Share invite link',
                  onPressed: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 53,
          child: Icon(icon, size: 22, color: LgtmColors.ink),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isYou});

  final LgtmMember member;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          LgtmAvatar(size: 38, fallbackColor: member.avatarColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LgtmSans.title.copyWith(color: LgtmColors.ink),
            ),
          ),
          if (isYou)
            LgtmPill(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              fill: LgtmColors.mint,
              borderColor: LgtmColors.mintBorder,
              child: Text(
                'You',
                style: LgtmSans.caption.copyWith(
                  color: LgtmColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final LgtmGroupSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          LgtmIconTile(icon: session.winnerIcon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.activity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LgtmSans.title.copyWith(color: LgtmColors.ink),
                ),
                Text(
                  session.winnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LgtmSans.bodySmall.copyWith(
                    color: LgtmColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            session.date,
            style: LgtmSans.caption.copyWith(color: LgtmColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// The Start Session CTA, pinned above the home indicator.
class _StartSessionBar extends StatelessWidget {
  const _StartSessionBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return ColoredBox(
      color: LgtmColors.bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LgtmLayout.gutterTight,
          12,
          LgtmLayout.gutterTight,
          16 + bottomInset,
        ),
        child: LgtmPrimaryButton(
          label: 'Start Session',
          icon: Icons.add_circle_outline,
          height: 56,
          shadows: LgtmShadow.primarySoft,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
