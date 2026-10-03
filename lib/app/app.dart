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
  });

  /// Overridden by tests to open straight onto a screen.
  final String initialRoute;

  /// Overridden by tests that need a known set of groups.
  final LgtmGroupsStore? groupsStore;

  /// Overridden by tests that need to start already signed in, or signed out.
  final LgtmSession? session;

  @override
  State<LgtmApp> createState() => _LgtmAppState();
}

class _LgtmAppState extends State<LgtmApp> {
  /// One session for the life of the app. The real one is built here when the
  /// Firebase work in TODO.md lands; every screen reads it through
  /// [LgtmSessionScope].
  late final LgtmSession _session = widget.session ?? LgtmSession();

  /// Same story for the groups: one mock store for the whole app, shared with
  /// every route through [LgtmGroupsScope].
  late final LgtmGroupsStore _groups = widget.groupsStore ?? LgtmGroupsStore();

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
