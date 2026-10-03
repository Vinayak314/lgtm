import 'auth_repository.dart';

/// The mock that stands in for Firebase Auth while there is no project to talk
/// to.
///
/// It accepts any credential that is filled in, keeps the user in memory, and
/// waits [delay] on every call so the screens keep showing a real loading
/// state instead of flashing for one frame. Passing [delay] as
/// [Duration.zero] is what the tests do.
class LgtmInMemoryAuthRepository implements LgtmAuthRepository {
  LgtmInMemoryAuthRepository({
    this.delay = const Duration(milliseconds: 800),
    this.restoreDelay = const Duration(milliseconds: 700),
    LgtmUser? signedInAs,
  }) : _user = signedInAs;

  /// How long a sign in, sign up or sign out pretends to take.
  final Duration delay;

  /// How long [restore] pretends to wait.
  final Duration restoreDelay;

  LgtmUser? _user;

  @override
  Future<LgtmUser?> restore() async {
    await Future<void>.delayed(restoreDelay);
    return _user;
  }

  @override
  Future<LgtmUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final address = email.trim();
    // No uid: there is no database here to key a record on, and inventing one
    // would make the mock disagree with the groups it is paired with.
    return _user = LgtmUser(
      displayName: LgtmUser.nameFromEmail(address),
      email: address,
    );
  }

  @override
  Future<LgtmUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    return _user = LgtmUser(
      displayName: displayName.trim(),
      email: email.trim(),
    );
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(delay);
    _user = null;
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    await Future<void>.delayed(delay);
    final user = _user;
    if (user == null) return;
    _user = user.copyWith(displayName: displayName.trim());
  }
}
