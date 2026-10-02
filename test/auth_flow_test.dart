import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/groups_store.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/app/session.dart';
import 'package:lgtm/app/theme.dart';
import 'package:lgtm/screens/auth/login_screen.dart';
import 'package:lgtm/screens/auth/sign_up_screen.dart';
import 'package:lgtm/screens/splash/auth_gate_screen.dart';
import 'package:lgtm/screens/splash/splash_screen.dart';

/// Pumps forward in short steps until [finder] matches. Needed because the
/// splash, the auth gate and the mock sign in all wait on timers.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int steps = 12,
  Duration step = const Duration(milliseconds: 400),
}) async {
  for (var i = 0; i < steps && finder.evaluate().isEmpty; i++) {
    await tester.pump(step);
  }
}

/// The app is a 390pt wide phone column, so the tests use a phone window too.
void usePhoneWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('launch', () {
    testWidgets('splash hands over to the auth gate, which routes to login', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);

      await tester.pumpWidget(const LgtmApp());
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      await pumpUntil(tester, find.byType(AuthGateScreen));
      await pumpUntil(tester, find.byType(LoginScreen));
      await tester.pump(const Duration(milliseconds: 400));

      // Both are replaced, not stacked.
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.byType(AuthGateScreen), findsNothing);
    });

    testWidgets('a signed in session goes straight to the app', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);

      final session = LgtmSession(
        restoreDelay: Duration.zero,
        authDelay: Duration.zero,
      );
      // Deliberately not awaited: under the test's fake clock this only
      // resolves on a pump, and the gate below must see the finished sign in.
      unawaited(
        session.signIn(email: 'purva@example.com', password: 'hunter2'),
      );

      await tester.pumpWidget(
        LgtmAppHarness(session: session, initialRoute: LgtmRoutes.authGate),
      );
      await tester.pump();
      await pumpUntil(tester, find.text('My Groups'));

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.text('My Groups'), findsOneWidget);
    });
  });

  group('login', () {
    testWidgets('an empty form explains every field instead of navigating', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
      await tester.pump();

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('a malformed email is called out in plain language', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(
        find.text("That email address doesn't look right."),
        findsOneWidget,
      );
    });

    testWidgets('the password can be revealed and hidden again', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
      await tester.pump();

      final password = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(password).obscureText, isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isTrue);
    });

    testWidgets('a valid sign in reaches the app and records the session', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      final session = LgtmSession();

      await tester.pumpWidget(
        LgtmAppHarness(session: session, initialRoute: LgtmRoutes.login),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'purva@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'hunter2hunter2');
      await tester.tap(find.text('Sign in'));

      await pumpUntil(tester, find.text('My Groups'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LoginScreen), findsNothing);
      expect(session.isSignedIn, isTrue);
      expect(session.user?.displayName, 'Purva');
      expect(session.user?.email, 'purva@example.com');
    });

    testWidgets('errors clear themselves once the field is being fixed', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
      await tester.pump();

      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Enter your email address.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'p');
      await tester.pump();

      expect(find.text('Enter your email address.'), findsNothing);
    });

    testWidgets('the social buttons say they are not connected yet', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
      await tester.pump();

      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      expect(find.text('Google sign in is not connected yet.'), findsOneWidget);
    });

    testWidgets('login offers a way to sign up', (WidgetTester tester) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
      await tester.pump();

      await tester.ensureVisible(find.text('New here? Create an account'));
      await tester.tap(find.text('New here? Create an account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });

  group('sign up', () {
    testWidgets('a valid sign up keeps the name it was given', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      final session = LgtmSession();

      await tester.pumpWidget(
        LgtmAppHarness(session: session, initialRoute: LgtmRoutes.signUp),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Purva');
      await tester.enterText(find.byType(TextField).at(1), 'purva@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'hunter2hunter2');
      await tester.enterText(find.byType(TextField).at(3), 'hunter2hunter2');

      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));

      await pumpUntil(tester, find.text('My Groups'));

      expect(session.isSignedIn, isTrue);
      expect(session.user?.displayName, 'Purva');
    });

    testWidgets('a mismatched confirmation stops the sign up', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      final session = LgtmSession();

      await tester.pumpWidget(
        LgtmAppHarness(session: session, initialRoute: LgtmRoutes.signUp),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'Purva');
      await tester.enterText(find.byType(TextField).at(1), 'purva@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'hunter2hunter2');
      await tester.enterText(find.byType(TextField).at(3), 'differentone');

      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
      expect(session.isSignedIn, isFalse);
    });
  });

  group('session', () {
    test('restore resolves to signed out when nobody is signed in', () async {
      final session = LgtmSession(restoreDelay: Duration.zero);

      expect(session.status, AuthStatus.unknown);
      await session.restore();

      expect(session.status, AuthStatus.signedOut);
      expect(session.user, isNull);
    });

    test('sign out puts the app back to signed out', () async {
      final session = LgtmSession(authDelay: Duration.zero);
      await session.signIn(email: 'purva@example.com', password: 'hunter2');
      expect(session.isSignedIn, isTrue);

      await session.signOut();

      expect(session.status, AuthStatus.signedOut);
      expect(session.user, isNull);
    });

    test('an email becomes a name to greet somebody by', () async {
      final session = LgtmSession(authDelay: Duration.zero);
      await session.signIn(email: 'purva.s@example.com', password: 'hunter2');

      expect(session.user?.displayName, 'Purva S');
    });
  });
}

/// The app shell with a session the test can inspect.
class LgtmAppHarness extends StatelessWidget {
  LgtmAppHarness({super.key, required this.session, this.initialRoute})
    : groups = LgtmGroupsStore(delay: Duration.zero);

  final LgtmSession session;
  final String? initialRoute;
  final LgtmGroupsStore groups;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: LgtmTheme.light,
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (name) => [
        lgtmGenerateRoute(RouteSettings(name: name)),
      ],
      onGenerateRoute: lgtmGenerateRoute,
      builder: (context, child) => LgtmGroupsScope(
        store: groups,
        child: LgtmSessionScope(session: session, child: child!),
      ),
    );
  }
}
