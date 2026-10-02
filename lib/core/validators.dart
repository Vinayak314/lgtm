/// Form field validators shared by every form in the app.
///
/// Each one returns `null` when the value is fine, or a complete sentence that
/// tells the person what to do. Never "Invalid input": an error has to be
/// readable on its own, under the field, with no context.
abstract final class LgtmValidators {
  /// Deliberately permissive: one `@`, something on both sides, no spaces.
  /// The server is the real authority on whether an address exists.
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Tell us what to call you.';
    if (text.length < 2) return 'That name looks too short.';
    if (text.length > 40) return 'Keep your name under 40 characters.';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(text)) return "That email address doesn't look right.";
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter your password.';
    if (text.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  /// Confirmation field check. Skipped when [password] is empty so the person
  /// is not told about a mismatch before they have typed anything.
  static String? passwordConfirmation(String? value, String password) {
    if (password.isEmpty) return null;
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  /// Invite codes are the short alphanumeric codes from a group invite link.
  static final _inviteCode = RegExp(r'^[A-Za-z0-9]{4,12}$');

  static String? inviteCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter the code your group shared.';
    if (!_inviteCode.hasMatch(text)) {
      return 'Codes are 4 to 12 letters or numbers.';
    }
    return null;
  }

  static String? groupName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Give your group a name.';
    if (text.length > 40) return 'Keep the name under 40 characters.';
    return null;
  }
}
