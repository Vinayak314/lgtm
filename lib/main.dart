import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/firebase_auth_repository.dart';
import 'data/realtime_groups_repository.dart';
import 'data/realtime_session_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android's google-services.json creates the native default app. Reuse that
  // app instead of trying to recreate it with Dart options, then pass the
  // regional database URL to the Realtime Database instance directly.
  await Firebase.initializeApp();
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.android.databaseURL,
  );

  runApp(
    LgtmApp(
      authRepository: FirebaseAuthRepository(database: database),
      groupsRepository: RealtimeGroupsRepository(database: database),
      sessionRepository: RealtimeSessionRepository(database: database),
    ),
  );
}
