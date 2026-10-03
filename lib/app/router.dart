import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/groups/create_group_screen.dart';
import '../screens/groups/group_detail_screen.dart';
import '../screens/groups/groups_hub_screen.dart';
import '../screens/groups/join_group_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/auth_gate_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/system/not_found_screen.dart';

/// Every route in the app, named once.
///
/// Screens navigate with these names and never with string literals or nested
/// `Navigator.push` calls, so a rename is a one line change and deep links
/// have somewhere to land.
abstract final class LgtmRoutes {
  /// Launch. Hands over to the auth gate.
  static const splash = '/';

  /// Restores the session, then routes to Login or the app.
  static const authGate = '/auth';

  static const login = '/login';

  /// Takes [SignUpArgs], so an invite link can arrive already filled in.
  static const signUp = '/sign-up';

  static const groups = '/groups';
  static const createGroup = '/groups/create';
  static const joinGroup = '/groups/join';

  /// Takes [GroupDetailArgs].
  static const groupDetail = '/groups/detail';

  static const profile = '/profile';
}

/// Arguments for [LgtmRoutes.signUp].
///
/// An invite link (`lgtm.app/invite/vYzA1`) opens sign up with the group code
/// already applied, so a new member never has to retype it.
class SignUpArgs {
  const SignUpArgs({this.inviteCode});

  final String? inviteCode;

  /// Reads the arguments off a route, tolerating a route pushed with none.
  static SignUpArgs fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    return args is SignUpArgs ? args : const SignUpArgs();
  }
}

/// Arguments for [LgtmRoutes.groupDetail].
class GroupDetailArgs {
  const GroupDetailArgs({required this.groupId});

  final String groupId;

  /// Reads the arguments off a route, or null when they are missing or wrong,
  /// which sends the person to the not found screen rather than crashing.
  static GroupDetailArgs? fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! GroupDetailArgs) return null;
    return args.groupId.isEmpty ? null : args;
  }
}

/// Builds every route in the app.
///
/// Anything unrecognised, and any screen that has not been built yet, lands on
/// [NotFoundScreen] rather than a dead end.
Route<Object?> lgtmGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LgtmRoutes.splash:
      return _page(settings, const SplashScreen());

    case LgtmRoutes.authGate:
      return _page(settings, const AuthGateScreen());

    case LgtmRoutes.login:
      return _page(settings, const LoginScreen());

    case LgtmRoutes.signUp:
      return _page(
        settings,
        SignUpScreen(args: SignUpArgs.fromRoute(settings)),
      );

    case LgtmRoutes.groups:
      return _page(settings, const GroupsHubScreen());

    case LgtmRoutes.createGroup:
      return _page(settings, const CreateGroupScreen());

    case LgtmRoutes.joinGroup:
      return _page(settings, const JoinGroupScreen());

    case LgtmRoutes.groupDetail:
      final args = GroupDetailArgs.fromRoute(settings);
      // A detail route with no usable group id has nothing to show.
      if (args == null) {
        return _page(settings, NotFoundScreen(path: settings.name));
      }
      return _page(settings, GroupDetailScreen(args: args));

    case LgtmRoutes.profile:
      return _page(settings, const ProfileScreen());

    default:
      return _page(settings, NotFoundScreen(path: settings.name));
  }
}

MaterialPageRoute<Object?> _page(RouteSettings settings, Widget child) {
  return MaterialPageRoute<Object?>(
    settings: settings,
    builder: (context) => child,
  );
}
