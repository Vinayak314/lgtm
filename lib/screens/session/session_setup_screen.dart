import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/session.dart';
import '../../app/groups_store.dart';
import '../../core/design_tokens.dart';
import '../../data/session_repository.dart';
import 'package:provider/provider.dart';
import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../models/session.dart';
import '../../widgets/lgtm_buttons.dart';
import '../../widgets/lgtm_top_bar.dart';
import 'lobby_screen.dart';
import 'swipe_screen.dart';

/// Arguments for the session setup screen.
class SessionSetupArgs {
  const SessionSetupArgs({required this.groupId});

  final String groupId;

  static SessionSetupArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! SessionSetupArgs || args.groupId.isEmpty) return null;
    return args;
  }
}

/// Session Setup: category picker, centre ornament, and "Start Swiping" CTA.
///
/// Follows section 4 of design.md: back arrow, "Session Setup" title bar,
/// category chips (FOOD selected by default and MOVIES), concentric
/// circle ornament, and the 8px radius CTA pinned near the bottom.
class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key, this.args});

  final SessionSetupArgs? args;

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  _Category _selected = _Category.food;
  bool _checkingActiveSession = true;
  bool _redirectedToActiveSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinActiveSessionIfPresent();
    });
  }

  Future<void> _joinActiveSessionIfPresent() async {
    final args = widget.args;
    final user = LgtmSessionScope.read(context).user;
    if (args == null || user == null) {
      if (mounted) setState(() => _checkingActiveSession = false);
      return;
    }

    final repository = context.read<LgtmSessionRepository>();
    try {
      final activeSessionId = await repository.activeSessionId(args.groupId);
      if (!mounted) return;

      if (activeSessionId == null) {
        setState(() => _checkingActiveSession = false);
        return;
      }

      // Fetch current session state to decide the right screen.
      final session = await repository.fetchSession(activeSessionId);
      if (!mounted) return;

      if (session == null) {
        // Session was deleted or doesn't exist. Clear the stale pointer.
        setState(() => _checkingActiveSession = false);
        return;
      }

      final bloc = SessionBloc(
        repository: repository,
        currentUserId: user.uid,
      );

      setState(() => _redirectedToActiveSession = true);

      switch (session.status) {
        case SessionStatus.lobby:
          // Lobby is still open — join normally.
          bloc.add(JoinLobbyEvent(sessionId: activeSessionId));
          await Navigator.of(context).pushReplacementNamed(
            LgtmRoutes.sessionLobby,
            arguments: LobbyArgs(
              groupId: args.groupId,
              sessionId: activeSessionId,
              bloc: bloc,
            ),
          );
          break;

        case SessionStatus.active:
        case SessionStatus.finished:
          // Session already started or finished. Rejoin without writing
          // to participants — just subscribe to the stream.
          bloc.add(RejoinSessionEvent(sessionId: activeSessionId));
          await Navigator.of(context).pushReplacementNamed(
            LgtmRoutes.sessionSwipe,
            arguments: SwipeArgs(
              groupId: args.groupId,
              sessionId: activeSessionId,
              category: session.category.wire,
              bloc: bloc,
            ),
          );
          break;
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _checkingActiveSession = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not join session: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingActiveSession || _redirectedToActiveSession) {
      return const Scaffold(
        backgroundColor: LgtmColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: Stack(
        children: [
          // Decorative blob (design.md §0: small, x 0-100, y 64-100).
          Positioned(left: -30, top: 56, child: _Blob(width: 130, height: 55)),
          Column(
            children: [
              LgtmTopBar(
                leading: LgtmIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  color: LgtmColors.inkMuted,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                center: Text(
                  'Session Setup',
                  style: LgtmSerif.title.copyWith(color: LgtmColors.ink),
                ),
                actions: [
                  LgtmIconButton(
                    icon: Icons.more_horiz,
                    tooltip: 'Options',
                    color: LgtmColors.inkMuted,
                    onPressed: () {},
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'Choose Activity Category',
                      style: LgtmSans.body.copyWith(
                        color: LgtmColors.inkMuted,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _CategoryChips(
                      selected: _selected,
                      onChanged: (cat) => setState(() => _selected = cat),
                    ),
                    const Spacer(),
                    const _CentreOrnament(),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
          // CTA pinned near the bottom.
          Positioned(
            left: 16,
            right: 16,
            bottom: 32 + MediaQuery.viewPaddingOf(context).bottom,
            child: LgtmPrimaryButton(
              label: 'Start Swiping',
              icon: Icons.arrow_forward,
              iconColor: Colors.white,
              iconSize: 20,
              height: 54,
              shape: LgtmButtonShape.square,
              shadows: LgtmShadow.primarySoft,
              labelStyle: LgtmSerif.body.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
              onPressed: widget.args == null ? null : _startSession,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    final args = widget.args;
    final user = LgtmSessionScope.read(context).user;
    if (args == null || user == null) return;

    final group = LgtmGroupsScope.read(context).groupById(args.groupId);
    final repository = context.read<LgtmSessionRepository>();
    final bloc = SessionBloc(
      repository: repository,
      currentUserId: user.uid,
    );
    if (group == null || group.ownerId != user.uid) {
      bloc.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the group owner can start a new session.'),
        ),
      );
      return;
    }
    bloc.add(
      SessionStartedEvent(
        groupId: args.groupId,
        categoryName: _selected.name,
      ),
    );
    Navigator.of(context).pushNamed(
      LgtmRoutes.sessionLobby,
      arguments: LobbyArgs(
        groupId: args.groupId,
        category: _selected.name,
        sessionId: '',
        bloc: bloc,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip selector
// ---------------------------------------------------------------------------

enum _Category { food, movies }

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onChanged});

  final _Category selected;
  final ValueChanged<_Category> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 22,
      runSpacing: 24,
      children: [
        _Chip(
          label: 'FOOD',
          icon: Icons.restaurant,
          isSelected: selected == _Category.food,
          onTap: () => onChanged(_Category.food),
        ),
        _Chip(
          label: 'MOVIES',
          icon: Icons.movie,
          isSelected: selected == _Category.movies,
          onTap: () => onChanged(_Category.movies),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? LgtmColors.primary : LgtmColors.inkMuted;
    final fill = isSelected ? LgtmColors.primarySoft : LgtmColors.surface;
    final border = isSelected ? LgtmColors.primary : LgtmColors.chipBorder;
    final shadows = isSelected ? LgtmShadow.chipHard : null;

    return Semantics(
      button: true,
      label: label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: border, width: isSelected ? 2 : 1),
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: LgtmSans.label.copyWith(
                  color: color,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Centre ornament (settings dial)
// ---------------------------------------------------------------------------

class _CentreOrnament extends StatelessWidget {
  const _CentreOrnament();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 252,
      height: 252,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer dotted circle.
          CustomPaint(
            size: const Size(252, 252),
            painter: _DottedCirclePainter(
              color: LgtmColors.ringOuter,
              strokeWidth: 2,
            ),
          ),
          // Middle solid circle.
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: LgtmColors.ringMiddle),
            ),
          ),
          // Inner button.
          GestureDetector(
            onTap: () {}, // Stub: opens extra filters.
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: LgtmColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: LgtmColors.dialBorder, width: 1.5),
                boxShadow: LgtmShadow.dialSoft,
              ),
              child: const Icon(
                Icons.tune,
                size: 56,
                color: LgtmColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedCirclePainter extends CustomPainter {
  const _DottedCirclePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final radius = (size.shortestSide - strokeWidth) / 2;
    final centre = Offset(size.width / 2, size.height / 2);
    const dashCount = 60;
    const dashArc = 0.035;
    const gapArc = (2 * math.pi / dashCount) - dashArc;

    final path = Path();
    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashArc + gapArc);
      path.addArc(
        Rect.fromCircle(center: centre, radius: radius),
        startAngle,
        dashArc,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DottedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// Decorative blob (shared style from design.md §0)
// ---------------------------------------------------------------------------

class _Blob extends StatelessWidget {
  const _Blob({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.9,
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            color: Color(0xFFEFECE8),
            borderRadius: BorderRadius.only(
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
