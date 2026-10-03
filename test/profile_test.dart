import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/groups_store.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/app/session.dart';
import 'package:lgtm/screens/auth/login_screen.dart';
import 'package:lgtm/screens/groups/groups_hub_screen.dart';
import 'package:lgtm/screens/profile/profile_screen.dart';
import 'package:lgtm/widgets/lgtm_avatar.dart';
import 'package:lgtm/widgets/lgtm_buttons.dart';
import 'package:lgtm/widgets/lgtm_top_bar.dart';

/// The app is a 390pt column, so the tests are too.
void usePhoneWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// A tap that pushes or replaces a route needs enough ticks of the transition
/// to take the screen underneath offstage.
Future<void> tapTo(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A session that is already signed in. The sign in itself waits on a timer,
/// which only fires outside the widget tester's fake clock.
Future<LgtmSession> signedInSession(
  WidgetTester tester, {
  String email = 'purva@example.com',
}) async {
  final session = LgtmSession(
    restoreDelay: Duration.zero,
    authDelay: Duration.zero,
  );
  await tester.runAsync(
    () => session.signIn(email: email, password: 'password123'),
  );
  return session;
}

Future<LgtmSession> openProfile(
  WidgetTester tester, {
  LgtmSession? session,
  LgtmGroupsStore? store,
}) async {
  final account = session ?? await signedInSession(tester);
  usePhoneWindow(tester);
  await tester.pumpWidget(
    LgtmApp(
      initialRoute: LgtmRoutes.profile,
      session: account,
      groupsStore: store ?? LgtmGroupsStore(delay: Duration.zero),
    ),
  );
  await tester.pump();
  await pumpUntil(tester, find.text('Purva'));
  // The screen asks for the groups itself, so give that read a frame to land
  // before anything counts them.
  await pumpUntil(tester, find.text('2 groups'));
  return account;
}

void main() {
  group('profile', () {
    testWidgets('shows who is signed in and how many groups they are in', (
      WidgetTester tester,
    ) async {
      final session = await openProfile(tester);

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Purva'), findsWidgets);
      expect(find.text('purva@example.com'), findsOneWidget);
      expect(find.text('2 groups'), findsOneWidget);
      expect(session.isSignedIn, isTrue);
    });

    testWidgets('Save stays off until the name is actually changed', (
      WidgetTester tester,
    ) async {
      await openProfile(tester);

      final save = tester.widget<LgtmPrimaryButton>(
        find.widgetWithText(LgtmPrimaryButton, 'Save Changes'),
      );
      expect(save.onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Purva S');
      await tester.pump();

      final edited = tester.widget<LgtmPrimaryButton>(
        find.widgetWithText(LgtmPrimaryButton, 'Save Changes'),
      );
      expect(edited.onPressed, isNotNull);
    });

    testWidgets('a name that is too short is called out and not saved', (
      WidgetTester tester,
    ) async {
      final session = await openProfile(tester);

      await tester.enterText(find.byType(TextField), 'P');
      await tester.pump();
      await tapTo(tester, find.text('Save Changes'));

      expect(find.text('That name looks too short.'), findsOneWidget);
      expect(session.user!.displayName, 'Purva');
    });

    testWidgets('saving a new name updates the session and says so', (
      WidgetTester tester,
    ) async {
      final session = await openProfile(tester);

      await tester.enterText(find.byType(TextField), 'Purva S');
      await tester.pump();
      await tapTo(tester, find.text('Save Changes'));
      await pumpUntil(
        tester,
        find.text('Saved. Your group buddies will see the new name.'),
      );

      expect(session.user!.displayName, 'Purva S');
      expect(session.user!.email, 'purva@example.com');
      expect(find.text('Purva S'), findsWidgets);
    });

    testWidgets('signing out asks first, and cancelling keeps the session', (
      WidgetTester tester,
    ) async {
      final session = await openProfile(tester);

      await tapTo(tester, find.text('Sign out'));
      expect(find.text('Sign out?'), findsOneWidget);

      await tapTo(tester, find.text('Cancel'));

      expect(find.text('Sign out?'), findsNothing);
      expect(session.isSignedIn, isTrue);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('confirming clears the session and lands on Login', (
      WidgetTester tester,
    ) async {
      final session = await openProfile(tester);

      await tapTo(tester, find.text('Sign out'));
      await tapTo(
        tester,
        find.descendant(
          of: find.byType(LgtmPrimaryButton),
          matching: find.text('Sign out'),
        ),
      );
      await pumpUntil(tester, find.byType(LoginScreen));

      expect(session.isSignedIn, isFalse);
      expect(session.user, isNull);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('the hub nav tab and the top bar avatar both open it', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.groups,
          session: await signedInSession(tester),
          groupsStore: LgtmGroupsStore(delay: Duration.zero),
        ),
      );
      await tester.pump();
      await pumpUntil(tester, find.byType(GroupsHubScreen));

      await tapTo(tester, find.text('Profile'));
      expect(find.byType(ProfileScreen), findsOneWidget);

      await tapTo(tester, find.text('Groups'));
      expect(find.byType(GroupsHubScreen), findsOneWidget);

      await tapTo(
        tester,
        find.descendant(
          of: find.byType(LgtmTopBar),
          matching: find.byType(LgtmAvatar),
        ),
      );
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
