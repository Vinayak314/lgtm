import '../models/user.dart';

/// The signed in person's own record in the database: `users/{uid}`.
///
/// Re-exported through `app/session.dart` so screens keep importing one file.
export '../models/user.dart';

/// How auth storage failed, in words a form can put on screen.
class LgtmAuthException implements Exception {
  const LgtmAuthException(this.message);

  /// A whole sentence, already trimmed and ready to show.
  final String message;

  @override
  String toString() => 'LgtmAuthException: $message';
}

/// Everything the app needs from "who is signed in, and can they sign in".
///
/// [LgtmSession] is the only caller. Screens never see this interface, they go
/// through the session, so Firebase Auth remains isolated from the screens.
abstract class LgtmAuthRepository {
  /// Works out whether anybody is signed in from whatever survives a restart.
  /// Resolves to null when nobody is.
  Future<LgtmUser?> restore();

  /// Signs in with a credential the storage already trusts. Throws
  /// [LgtmAuthException] when the password does not match.
  Future<LgtmUser> signIn({required String email, required String password});

  /// Signs in with Google. Returns null when the person cancels the flow.
  Future<LgtmUser?> signInWithGoogle();

  /// Creates the account and signs in. Throws [LgtmAuthException] when the
  /// address is already taken.
  Future<LgtmUser> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Writes a new display name to the signed in person's own record. Throws
  /// [LgtmAuthException] when the write is rejected.
  Future<void> updateDisplayName(String displayName);
}
