import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/demo_mode.dart';
import 'data/firebase_auth_repository.dart';
import 'data/realtime_groups_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A demo build runs on the in-memory mocks and nothing else, so Firebase is
  // never initialised: no project, no rules, no network, and the app starts
  // with the seeded groups. Left out, `LgtmApp` falls back to the mocks itself.
  if (lgtmDemoMode) {
    runApp(const LgtmApp());
    return;
  }

  // Firebase has to be up before any repository is used. `flutterfire
  // configure` wrote the options from the `lgtm-app` project, so the same
  // binary works on every device without a checked in api key of its own.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    LgtmApp(
      authRepository: FirebaseAuthRepository(),
      groupsRepository: RealtimeGroupsRepository(),
    ),
  );
}
