import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/demo_mode.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/app/session.dart';
import 'package:lgtm/data/in_memory_groups_repository.dart';
import 'package:lgtm/screens/auth/login_screen.dart';
import 'package:lgtm/screens/groups/groups_hub_screen.dart';
import 'package:lgtm/widgets/lgtm_demo_hint.dart';

import 'auth_flow_test.dart' show pumpUntil, usePhoneWindow;

/// Pumps the login screen on its own, inside the scope it reads.
///
/// [LoginScreen.showDemoHint] is a compile time flag in the app, so the screen
/// under test is told which way to go rather than the build being rebuilt
/// around it.
Future<LgtmSession> pumpLogin(
  WidgetTester tester, {
  required bool showDemoHint,
}) async {
  final session = LgtmSession(
    restoreDelay: Duration.zero,
    authDelay: Duration.zero,
  );

  await tester.pumpWidget(
    LgtmSessionScope(
      session: session,
      child: MaterialApp(home: LoginScreen(showDemoHint: showDemoHint)),
    ),
  );
  await tester.pump();
  return session;
}

void main() {
  group('demo mode', () {
    testWidgets('a normal build shows no demo card', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);

      // Off unless the build asked for it, which a test run never does.
      expect(lgtmDemoMode, isFalse);

      await pumpLogin(tester, showDemoHint: false);

      expect(find.byType(LgtmDemoHint), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('the demo card names credentials that pass the form rules', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);

      await pumpLogin(tester, showDemoHint: true);

      expect(find.text('Demo mode'), findsOneWidget);
      // The pair is set as spans inside one paragraph, so the finder has to
      // look at rich text too.
      expect(
        find.textContaining(demoEmail, findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(demoPassword, findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('tapping the demo card fills the form and clears errors', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await pumpLogin(tester, showDemoHint: true);

      // A wrong attempt first, so there is a red line left to clear.
      await tester.enterText(find.byType(TextField).first, 'nope');
      await tester.enterText(find.byType(TextField).last, 'short');
      // The card pushes the button below the fold on a 390pt phone, so it is
      // scrolled to rather than tapped where it happens to sit.
      await tester.ensureVisible(find.text('Sign in'));
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(
        find.text("That email address doesn't look right."),
        findsOneWidget,
      );
      expect(find.text('Use at least 8 characters.'), findsOneWidget);

      await tester.ensureVisible(find.byType(LgtmDemoHint));
      await tester.tap(find.byType(LgtmDemoHint));
      await tester.pump();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.controller?.text, demoEmail);
      expect(fields.last.controller?.text, demoPassword);
      expect(find.text("That email address doesn't look right."), findsNothing);
      expect(find.text('Use at least 8 characters.'), findsNothing);
    });

    testWidgets(
      'those credentials sign in on the mock, with the seeded groups',
      (WidgetTester tester) async {
        usePhoneWindow(tester);

        // No repositories, exactly as main.dart builds a demo: the mock pair is
        // what everything falls back to.
        await tester.pumpWidget(const LgtmApp(initialRoute: LgtmRoutes.login));
        await tester.pump();
        await pumpUntil(tester, find.byType(LoginScreen));

        await tester.enterText(find.byType(TextField).first, demoEmail);
        await tester.enterText(find.byType(TextField).last, demoPassword);
        await tester.tap(find.text('Sign in'));
        await tester.pump();

        await pumpUntil(tester, find.byType(GroupsHubScreen));
        expect(find.byType(GroupsHubScreen), findsOneWidget);

        // The seeded groups, so a demo has something to show before anything is
        // created or joined. The mock store takes its time on purpose.
        await pumpUntil(tester, find.text('Roommates'));
        expect(find.text('Roommates'), findsOneWidget);
        expect(find.text('Hackathon Squad'), findsOneWidget);
      },
    );

    test('the advertised codes are the codes the seeded groups answer to', () {
      // A demo of joining needs something to type, so the pair the flag
      // advertises has to be the pair the seed data carries.
      final codes = mockGroups().map((group) => group.inviteCode).toList();
      expect(codes, demoInviteCodes);
    });
  });
}
