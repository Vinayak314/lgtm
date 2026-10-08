import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../core/design_tokens.dart';
import '../../widgets/lgtm_avatar.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_top_bar.dart';
import 'swipe_screen.dart';

/// Arguments for the lobby screen.
class LobbyArgs {
  const LobbyArgs({
    required this.groupId,
    this.sessionId = '',
    this.category = 'food',
  });

  final String groupId;
  final String sessionId;
  final String category;

  static LobbyArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! LobbyArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

/// The lobby screen: members join, the host taps Begin.
///
/// Participant avatars and the host action use demo data until live session
/// state is connected. Begin still advances through the same session routes.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, this.args});

  final LobbyArgs? args;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  // Mock participants until real session data is wired.
  final List<_MockParticipant> _participants = [
    _MockParticipant('You', const Color(0xFF4A4A4A), true),
    _MockParticipant('Purva', const Color(0xFF2F5D5B), true),
    _MockParticipant('Alex', const Color(0xFF4B3F63), true),
  ];

  final List<_MockParticipant> _waiting = [
    _MockParticipant('Sam', const Color(0xFF5B4A3A), false),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _participants.length + _waiting.length;
    final joined = _participants.length;

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Column(
        children: [
          LgtmTopBar(
            leading: LgtmIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              color: LgtmColors.primary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            center: Text(
              'Lobby',
              style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LgtmLayout.gutter,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Live participant counter.
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: LgtmColors.green.withValues(
                                alpha: 0.5 + _pulseController.value * 0.5,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$joined / $total members joined',
                            style: LgtmSans.body.copyWith(
                              color: LgtmColors.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  // Participant grid.
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisExtent: 112,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 16,
                      children: [
                        for (final p in _participants)
                          _ParticipantTile(participant: p),
                        for (final p in _waiting)
                          _ParticipantTile(participant: p),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Waiting message.
                  if (_waiting.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Waiting for ${_waiting.length} more...',
                        style: LgtmSans.bodySmall.copyWith(
                          color: LgtmColors.inkSoft,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BeginBar(
        enabled: widget.args != null && _participants.isNotEmpty,
        onPressed: () {
          Navigator.of(context).pushReplacementNamed(
            LgtmRoutes.sessionSwipe,
            arguments: SwipeArgs(
              groupId: widget.args?.groupId ?? '',
              category: widget.args?.category ?? 'food',
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _MockParticipant {
  const _MockParticipant(this.name, this.color, this.hasJoined);

  final String name;
  final Color color;
  final bool hasJoined;
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.participant});

  final _MockParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: participant.hasJoined ? 1.0 : 0.4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LgtmAvatar(size: 56, fallbackColor: participant.color),
          const SizedBox(height: 8),
          Text(
            participant.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LgtmSans.caption.copyWith(
              color: LgtmColors.ink,
              fontWeight: participant.hasJoined
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          if (participant.hasJoined)
            const Icon(Icons.check_circle, size: 16, color: LgtmColors.green)
          else
            Icon(Icons.hourglass_empty, size: 16, color: LgtmColors.inkSoft),
        ],
      ),
    );
  }
}

class _BeginBar extends StatelessWidget {
  const _BeginBar({required this.enabled, required this.onPressed});

  final bool enabled;
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
          label: 'Begin',
          icon: Icons.play_arrow_rounded,
          height: 56,
          shadows: LgtmShadow.primarySoft,
          onPressed: enabled ? onPressed : null,
        ),
      ),
    );
  }
}
