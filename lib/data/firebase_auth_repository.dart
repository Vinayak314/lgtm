import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/json.dart';
import 'auth_repository.dart';

/// Firebase Auth, writing the profile to `users/{uid}` and the display name
/// the group cards read to `publicProfiles/{uid}`.
///
/// The Auth SDK owns the password and the email; the display name lives in our
/// own record so the hub can show it without asking Auth for it. Sign up writes
/// both, and every failure comes back as an [LgtmAuthException] with a
/// sentence a form can show as is, because "FirebaseException" helps nobody.
class FirebaseAuthRepository implements LgtmAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseDatabase? database})
    : _auth = auth ?? FirebaseAuth.instance,
      _database = database ?? FirebaseDatabase.instance;

  final FirebaseAuth _auth;

  /// Where `users/{uid}` lives.
  final FirebaseDatabase _database;

  /// Reads the profile for the signed in user, once [restore] or a sign in has
  /// resolved. Null until then.
  LgtmUser? _user;

  /// The user the Auth SDK is holding, or null when nobody is signed in.
  User? get currentUser => _auth.currentUser;

  @override
  Future<LgtmUser?> restore() async {
    // Firebase restores the session itself, so there is nothing to wait for:
    // currentUser is already known by the time the app starts.
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      _user = await _readProfile(user);
    } on FirebaseException {
      // The session is real even when the profile node cannot be read, so the
      // app opens with what Auth already knows rather than refusing to start.
      _user = _profileFrom(user);
    }
    return _user;
  }

  @override
  Future<LgtmUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const LgtmAuthException('Sign in did not work.');

      _user = await _readProfile(user);
      return _user!;
    } on FirebaseAuthException catch (failure) {
      throw LgtmAuthException(_messageFor(failure));
    } on FirebaseException catch (failure) {
      // A refused profile write must not escape as a driver error: the form
      // shows a sentence or nothing, never a stack trace and never a spinner
      // that stops.
      throw LgtmAuthException(_messageForDatabase(failure));
    }
  }

  @override
  Future<LgtmUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const LgtmAuthException('Sign up did not work.');

      final name = displayName.trim();
      // The Auth display name is what shows in Firebase's own console, so it is
      // kept in step with ours rather than left blank.
      await user.updateDisplayName(name);

      final profile = LgtmUser(
        uid: user.uid,
        displayName: name,
        email: user.email ?? email.trim(),
      );
      await _writeProfile(profile);

      _user = profile;
      return profile;
    } on FirebaseAuthException catch (failure) {
      throw LgtmAuthException(_messageFor(failure));
    } on FirebaseException catch (failure) {
      throw LgtmAuthException(_messageForDatabase(failure));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const LgtmAuthException('Sign in again to change your name.');
    }

    try {
      await user.updateDisplayName(displayName.trim());
    } on FirebaseAuthException catch (failure) {
      throw LgtmAuthException(_messageFor(failure));
    }

    final profile = (_user ?? _profileFrom(user)).copyWith(
      displayName: displayName.trim(),
    );
    try {
      await _writeProfile(profile);
    } on FirebaseException catch (failure) {
      throw LgtmAuthException(_messageForDatabase(failure));
    }
    _user = profile;
  }

  /// The profile as Auth knows it, for an account whose record is not there
  /// yet. The name never comes back empty, because the rules will not store an
  /// empty one and an account can arrive without a name at all.
  LgtmUser _profileFrom(User user) => LgtmUser(
    uid: user.uid,
    displayName: LgtmUser.nameFromEmail(
      user.displayName?.trim().isNotEmpty == true
          ? user.displayName
          : user.email,
    ),
    email: user.email ?? '',
  );

  /// Reads `users/{uid}`, falling back to what Auth already knows so a missing
  /// record cannot lock somebody out of the app.
  ///
  /// Also tops up `publicProfiles/{uid}` when it is not there yet, which is how
  /// an account made before that node existed ends up with a name on its cards
  /// without anybody having to sign up again. That top up is a convenience, so
  /// it is not allowed to fail the sign in: the person is already in, and their
  /// name can be set from the profile screen instead.
  Future<LgtmUser> _readProfile(User user) async {
    final snapshot = await _database.ref('users/${user.uid}').get();
    final stored = snapshot.value;
    final profile = stored is Map
        ? LgtmUser.fromJson(user.uid, jsonAsMap(stored))
        : _profileFrom(user);

    final public = await _database.ref('publicProfiles/${user.uid}').get();
    if (public.value is! Map) {
      // Everyone else's group cards read this. Not having it yet costs a
      // placeholder, and the rules can refuse a write the caller must not see,
      // so a failure here is not the caller's problem.
      try {
        await _writePublicProfile(profile);
      } on FirebaseException {
        // Nothing to do about it.
      }
    }
    return profile;
  }

  Future<void> _writeProfile(LgtmUser profile) async {
    await _database.ref('users/${profile.uid}').set(profile.toJson());
    await _writePublicProfile(profile);
  }

  /// The name group cards show. Deliberately not the email: every signed in
  /// person can read this node.
  Future<void> _writePublicProfile(LgtmUser profile) => _database
      .ref('publicProfiles/${profile.uid}')
      .set({'name': profile.displayName});

  /// Turns the Auth error codes the app can actually hit into plain language.
  static String _messageFor(FirebaseAuthException failure) =>
      switch (failure.code) {
        'invalid-email' => 'That email address does not look right.',
        'email-already-in-use' =>
          'There is already an account with that email.',
        'weak-password' => 'Pick a password with at least 6 characters.',
        'user-disabled' => 'That account has been turned off.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'That email and password do not match an account.',
        'too-many-requests' => 'Too many tries. Wait a moment and try again.',
        'network-request-failed' =>
          'No connection. Check the network and try again.',
        _ => 'Something went wrong. Try again.',
      };

  /// The same for a profile write the database refused, which is a different
  /// failure with a different fix and must not read like a wrong password.
  static String _messageForDatabase(FirebaseException failure) =>
      switch (failure.code) {
        'permission-denied' =>
          'We could not save your profile. Try again in a moment.',
        'unavailable' || 'network-request-failed' =>
          'No connection. Check the network and try again.',
        _ => 'Something went wrong saving your profile. Try again.',
      };
}
