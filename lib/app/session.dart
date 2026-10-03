import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../data/auth_repository.dart';
import '../data/in_memory_auth_repository.dart';

export '../data/auth_repository.dart';

/// Who is signed in, for the lifetime of the app.
///
/// This is the state Provider watches, and the only thing screens talk to for
/// auth: they read it through [LgtmSessionScope]. It owns the view state (status,
/// the signed in person, the last failure) and asks an [LgtmAuthRepository] for
/// the data, so the Firebase Auth implementation can slot in without a screen
/// changing.
///
/// With no repository passed in it builds the in-memory mock, which is why the
/// app still runs with no Firebase project.
class LgtmSession extends ChangeNotifier {
  LgtmSession({
    this.restoreDelay = const Duration(milliseconds: 700),
    this.authDelay = const Duration(milliseconds: 800),
    LgtmAuthRepository? repository,
  }) : _repository =
           repository ??
           LgtmInMemoryAuthRepository(
             delay: authDelay,
             restoreDelay: restoreDelay,
           );

  /// How long [restore] pretends to wait. Kept for the mock: the Firebase
  /// implementation takes whatever its own restore actually costs.
  final Duration restoreDelay;

  /// How long a sign in or sign up pretends to take. Same reasoning as
  /// [restoreDelay].
  final Duration authDelay;

  final LgtmAuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  LgtmUser? _user;
  String? _error;

  AuthStatus get status => _status;
  LgtmUser? get user => _user;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Set when the last attempt failed, written as a sentence the form can
  /// show as is.
  String? get error => _error;

  /// Works out whether anybody is signed in. The auth gate calls this once at
  /// launch. With the mock and no persistence there is nobody, so it resolves
  /// signed out.
  Future<void> restore() async {
    final restored = await _repository.restore();
    if (_status != AuthStatus.unknown) return;

    _user = restored;
    _status = restored == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  /// Signs in with an email and password.
  Future<bool> signIn({required String email, required String password}) =>
      _authenticate(() => _repository.signIn(email: email, password: password));

  /// Creates the account and signs in.
  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => _authenticate(
    () => _repository.signUp(
      displayName: displayName,
      email: email,
      password: password,
    ),
  );

  Future<bool> _authenticate(Future<LgtmUser> Function() attempt) async {
    _error = null;
    notifyListeners();

    try {
      _user = await attempt();
    } on LgtmAuthException catch (failure) {
      _user = null;
      _status = AuthStatus.signedOut;
      _error = failure.message;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _status = AuthStatus.signedOut;
    _error = null;
    notifyListeners();
  }

  /// Renames the signed in person from the Profile screen, which is where the
  /// write to `users/{uid}` now goes. Ignored when nobody is signed in, so it
  /// can never resurrect a session.
  Future<bool> updateDisplayName(String displayName) async {
    final user = _user;
    if (user == null) return false;

    try {
      await _repository.updateDisplayName(displayName);
    } on LgtmAuthException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    }

    _user = user.copyWith(displayName: displayName.trim());
    notifyListeners();
    return true;
  }

  /// Clears a failure message once the form has been edited.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

/// Whether we know yet who is signed in.
enum AuthStatus {
  /// Still restoring, nothing can be routed until this resolves.
  unknown,

  /// Nobody is signed in, send them to the Login screen.
  signedOut,

  /// Somebody is signed in, send them to the app proper.
  signedIn,
}

/// Makes the one [LgtmSession] available to every route through Provider.
///
/// A thin adapter over `ChangeNotifierProvider`, so screens keep calling
/// [LgtmSessionScope.of] and Provider stays the source of truth: whichever
/// scope is nearest wins, and nothing else has to be threaded through the tree.
class LgtmSessionScope extends StatelessWidget {
  const LgtmSessionScope({
    super.key,
    required this.session,
    required this.child,
  });

  final LgtmSession session;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<LgtmSession>.value(value: session, child: child);

  /// Read the session and rebuild when it changes.
  static LgtmSession of(BuildContext context) =>
      Provider.of<LgtmSession>(context);

  /// Read the session without subscribing, for one off calls such as a
  /// submission.
  static LgtmSession read(BuildContext context) => context.read<LgtmSession>();
}
