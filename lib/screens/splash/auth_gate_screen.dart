import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/session.dart';
import '../../core/design_tokens.dart';
import '../../widgets/design_canvas.dart';
import '../../widgets/states/lgtm_error_state.dart';
import '../../widgets/states/lgtm_loading_state.dart';

/// The auth state screen. It shows a loading state while the session works out
/// who is signed in, then replaces itself with the Login screen or the app
/// itself. It never guesses: while [AuthStatus.unknown] it stays put.
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _restoreStarted = false;
  bool _redirected = false;
  String? _failure;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restore();
  }

  void _restore() {
    if (_restoreStarted) return;
    _restoreStarted = true;

    final session = LgtmSessionScope.read(context);
    session.restore().catchError((Object error) {
      if (!mounted) return;
      setState(
        () => _failure =
            'We could not reach LGTM. Check your connection and try again.',
      );
    });
  }

  void _redirect(AuthStatus status) {
    if (_redirected || status == AuthStatus.unknown) return;
    _redirected = true;

    final route = status == AuthStatus.signedIn
        ? LgtmRoutes.groups
        : LgtmRoutes.login;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    _redirect(LgtmSessionScope.of(context).status);

    final failure = _failure;
    final body = failure != null
        ? LgtmErrorState(
            title: 'Something went wrong',
            message: failure,
            onRetry: () {
              setState(() {
                _failure = null;
                _restoreStarted = false;
              });
              _restore();
            },
          )
        : const LgtmLoadingState(label: 'Checking your account...');

    return Scaffold(
      backgroundColor: LgtmColors.bg,
      body: LgtmStatusBarInset(child: body),
    );
  }
}
