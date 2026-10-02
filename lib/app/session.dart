import 'package:flutter/widgets.dart';

/// Whether we know yet who is signed in.
enum AuthStatus {
  /// Still restoring, nothing can be routed until this resolves.
  unknown,

  /// Nobody is signed in, send them to the Login screen.
  signedOut,

  /// Somebody is signed in, send them to the app proper.
  signedIn,
}

/// The signed in person, as far as the app is concerned.
class LgtmUser {
  const LgtmUser({required this.displayName, required this.email});

  final String displayName;
  final String email;
}

/// Who is signed in, held in memory for the lifetime of the app.
///
/// This is deliberately a mock. Firebase, Realtime Database and persistence
/// are the backend items in TODO.md and are not started yet, so nothing here
/// touches the network or the disk. It is written as the seam the real
/// implementation will slot into: screens only ever talk to this object, so
/// swapping it later should not change a single screen.
class LgtmSession extends ChangeNotifier {
  LgtmSession({
    this.restoreDelay = const Duration(milliseconds: 700),
    this.authDelay = const Duration(milliseconds: 800),
  });

  /// How long [restore] pretends to wait. Keeps the loading state honest
  /// instead of flashing for one frame.
  final Duration restoreDelay;

  /// How long a sign in or sign up pretends to take.
  final Duration authDelay;

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
  /// launch; with no persistence there is nobody, so it resolves signed out.
  Future<void> restore() async {
    await Future<void>.delayed(restoreDelay);
    if (_status == AuthStatus.unknown) {
      _status = AuthStatus.signedOut;
      notifyListeners();
    }
  }

  /// Accepts any well formed credential until the real sign in lands.
  Future<bool> signIn({required String email, required String password}) {
    return _authenticate(
      LgtmUser(displayName: _nameFromEmail(email), email: email.trim()),
    );
  }

  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
  }) {
    return _authenticate(
      LgtmUser(displayName: displayName.trim(), email: email.trim()),
    );
  }

  Future<bool> _authenticate(LgtmUser user) async {
    _error = null;
    notifyListeners();

    await Future<void>.delayed(authDelay);

    _user = user;
    _status = AuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    await Future<void>.delayed(authDelay);
    _user = null;
    _status = AuthStatus.signedOut;
    _error = null;
    notifyListeners();
  }

  /// Clears a failure message once the form has been edited.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Turns an email into something to greet someone by, until the real profile
  /// exists: "purva.s@example.com" becomes "Purva S".
  static String _nameFromEmail(String email) {
    final words = email
        .trim()
        .split('@')
        .first
        .split(RegExp(r'[^A-Za-z]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'Friend';
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

/// Makes the one [LgtmSession] available to every route.
class LgtmSessionScope extends InheritedNotifier<LgtmSession> {
  const LgtmSessionScope({
    super.key,
    required LgtmSession session,
    required super.child,
  }) : super(notifier: session);

  /// Read the session and rebuild when it changes.
  static LgtmSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LgtmSessionScope>()!.notifier!;

  /// Read the session without subscribing, for one off calls such as a
  /// submission.
  static LgtmSession read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LgtmSessionScope>()!.notifier!;
}
