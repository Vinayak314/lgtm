import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../widgets/design_canvas.dart';
import 'groups_store.dart';
import 'router.dart';
import 'session.dart';
import 'theme.dart';

/// Root of the LGTM app shell.
class LgtmApp extends StatefulWidget {
  const LgtmApp({
    super.key,
    this.initialRoute = LgtmRoutes.splash,
    this.groupsStore,
    this.session,
    this.authRepository,
    this.groupsRepository,
  });

  /// Overridden by tests to open straight onto a screen.
  final String initialRoute;

  /// Overridden by tests that need a known set of groups.
  final LgtmGroupsStore? groupsStore;

  /// Overridden by tests that need to start already signed in, or signed out.
  final LgtmSession? session;

  /// Where auth is stored. `main.dart` passes Firebase Auth; left out, as in
  /// every test, the in-memory mock is used, which is why the app also runs
  /// with no Firebase project behind it.
  final LgtmAuthRepository? authRepository;

  /// Where groups are stored, with the same fallback as [authRepository].
  final LgtmGroupsRepository? groupsRepository;

  @override
  State<LgtmApp> createState() => _LgtmAppState();
}

class _LgtmAppState extends State<LgtmApp> {
  /// One session for the life of the app. Every screen reads it through
  /// [LgtmSessionScope].
  late final LgtmSession _session =
      widget.session ?? LgtmSession(repository: widget.authRepository);

  /// Same story for the groups: one store for the whole app, shared with every
  /// route through [LgtmGroupsScope].
  late final LgtmGroupsStore _groups =
      widget.groupsStore ??
      LgtmGroupsStore(repository: widget.groupsRepository);

  @override
  void initState() {
    super.initState();
    // The signed in person is who the hub marks as "you", and in the database
    // that person is a uid. Watching the session keeps the two in step without
    // either screen knowing the other exists.
    _session.addListener(_followSignedInUser);
    _followSignedInUser();
  }

  @override
  void dispose() {
    _session.removeListener(_followSignedInUser);
    _session.dispose();
    _groups.dispose();
    super.dispose();
  }

  /// Puts the signed in person in the groups store as its current member.
  ///
  /// The mock store keeps its own member, which is why nothing happens while a
  /// test runs on the mock: a user with no uid cannot be a real member.
  void _followSignedInUser() {
    final user = _session.user;
    if (user == null || user.uid.isEmpty) return;
    _groups.setCurrentMember(LgtmMember.fromUser(user));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LGTM',
      debugShowCheckedModeBanner: false,
      theme: LgtmTheme.light,
      initialRoute: widget.initialRoute,
      onGenerateInitialRoutes: (name) => [
        // Start on exactly one screen: the default "/" must not leave a copy
        // of itself underneath for the back gesture to pop back to.
        lgtmGenerateRoute(RouteSettings(name: name)),
      ],
      onGenerateRoute: lgtmGenerateRoute,
      builder: (context, child) {
        // Mobile first: the whole app is a 390pt column, centred on wider
        // screens with cream everywhere else.
        return LgtmGroupsScope(
          store: _groups,
          child: LgtmSessionScope(
            session: _session,
            child: DesignCanvas(
              backgroundColor: LgtmColors.bg,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
