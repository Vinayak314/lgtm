import 'json.dart';

/// The signed in person, as the app and the database see them.
///
/// Lives at `users/{uid}`, so [uid] is the key it is stored under and is not
/// repeated in the payload. [fcmToken] is the push token from TODO item 11;
/// it is written once notifications land and is null until then.
class LgtmUser {
  const LgtmUser({
    this.uid = '',
    required this.displayName,
    required this.email,
    this.fcmToken,
  });

  /// Firebase Auth uid. Empty in the mock, where nobody has signed up yet.
  final String uid;

  final String displayName;
  final String email;
  final String? fcmToken;

  /// Reads `users/{uid}`. Missing fields fall back rather than throw, so a
  /// profile written by an older build still loads.
  factory LgtmUser.fromJson(String uid, Map<String, Object?> json) => LgtmUser(
    uid: uid,
    displayName: jsonAsString(json['name'], fallback: 'Friend'),
    email: jsonAsString(json['email']),
    fcmToken: switch (jsonAsString(json['fcmToken'])) {
      '' => null,
      final token => token,
    },
  );

  /// Reads a `users` collection, keeping only the entries that are objects.
  /// Keys that Firebase forbids (`.`, `$`, `#`, `/`, `[`, `]`) are dropped by
  /// the database itself, so a key can differ from the stored id.
  static List<LgtmUser> listFromJson(Map<String, Object?> json) => [
    for (final entry in json.entries)
      if (entry.value is Map)
        LgtmUser.fromJson(entry.key, jsonAsMap(entry.value)),
  ];

  Map<String, Object?> toJson() => {
    'name': displayName,
    'email': email,
    if (fcmToken != null) 'fcmToken': fcmToken,
  };

  LgtmUser copyWith({String? displayName, String? email, String? fcmToken}) =>
      LgtmUser(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        fcmToken: fcmToken ?? this.fcmToken,
      );

  /// A name to show for somebody who has not given one.
  ///
  /// The rules will not store an empty name, and an account does not always
  /// arrive with one: it can be made in the Firebase console, or come from a
  /// social sign in that carried no name. The address is the only thing there
  /// is to work from, so "purva.s@example.com" becomes "Purva S" rather than a
  /// profile that cannot be written.
  static String nameFromEmail(String? email, {String fallback = 'Friend'}) {
    final words = (email ?? '')
        .trim()
        .split('@')
        .first
        .split(RegExp(r'[^A-Za-z]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return fallback;
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
