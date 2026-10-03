/// Whether this build runs on the in-memory mocks instead of Firebase.
///
/// Built with `flutter run --dart-define=LGTM_DEMO=true`, which is the same
/// flag `flutter build apk --dart-define=LGTM_DEMO=true` takes for a demo APK.
///
/// Nothing touches Firebase while this is on: `main.dart` skips initialising it
/// and hands [LgtmApp] no repositories, so every screen falls back to the mock
/// pair. The result starts with no project, no rules and no network, signs in
/// anybody, and serves the seeded groups from `mockGroups()`.
const bool lgtmDemoMode = bool.fromEnvironment('LGTM_DEMO');

/// The address a demo build expects to be given. The mock accepts any filled in
/// pair, so this exists to be shown on screen and typed with one tap rather than
/// because it is checked anywhere.
const demoEmail = 'demo@lgtm.app';

/// At least eight characters, because the form's own rule is checked before the
/// mock ever sees it.
const demoPassword = 'lgtm-demo';

/// The codes the two seeded groups answer to, so a demo that shows joining has
/// something to type. [Roommates] is `vYzA1` and [Hackathon Squad] is `x7ZA1`.
const demoInviteCodes = ['vYzA1', 'x7ZA1'];
