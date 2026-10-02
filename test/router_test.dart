import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/app/session.dart';
import 'package:lgtm/app/theme.dart';
import 'package:lgtm/screens/auth/sign_up_screen.dart';
import 'package:lgtm/screens/system/not_found_screen.dart';

void main() {
  group('route arguments', () {
    test('sign up reads the invite code off its route', () {
      final settings = RouteSettings(
        name: LgtmRoutes.signUp,
        arguments: const SignUpArgs(inviteCode: 'vYzA1'),
      );

      expect(SignUpArgs.fromRoute(settings).inviteCode, 'vYzA1');
    });

    test('sign up copes with a route pushed with no arguments', () {
      expect(
        SignUpArgs.fromRoute(const RouteSettings(name: LgtmRoutes.signUp))
            .inviteCode,
        isNull,
      );
      expect(
        SignUpArgs.fromRoute(
          const RouteSettings(name: LgtmRoutes.signUp, arguments: 'oops'),
        ).inviteCode,
        isNull,
      );
    });

    test('group detail rejects a missing or empty group id', () {
      expect(
        GroupDetailArgs.fromRoute(
          const RouteSettings(name: LgtmRoutes.groupDetail),
        ),
        isNull,
      );
      expect(
        GroupDetailArgs.fromRoute(
          const RouteSettings(
            name: LgtmRoutes.groupDetail,
            arguments: GroupDetailArgs(groupId: ''),
          ),
        ),
        isNull,
      );
      expect(
        GroupDetailArgs.fromRoute(
          const RouteSettings(
            name: LgtmRoutes.groupDetail,
            arguments: GroupDetailArgs(groupId: 'roommates'),
          ),
        )?.groupId,
        'roommates',
      );
    });
  });

  testWidgets('a path the app does not know shows the not found screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LgtmApp(initialRoute: '/not/a/route'));
    await tester.pump();

    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.textContaining('/not/a/route'), findsOneWidget);
  });

  testWidgets('the not found screen gets back into the app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LgtmApp(initialRoute: '/nope'));
    await tester.pump();

    await tester.tap(find.text('Go to LGTM'));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(NotFoundScreen), findsNothing);
    expect(find.text('LGTM'), findsOneWidget);
  });

  testWidgets('sign up shows the invite code it was routed with', (
    WidgetTester tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: LgtmTheme.light,
        initialRoute: LgtmRoutes.login,
        onGenerateRoute: lgtmGenerateRoute,
        builder: (context, child) => LgtmSessionScope(
          session: LgtmSession(restoreDelay: Duration.zero),
          child: child!,
        ),
      ),
    );

    navigator.currentState!.pushNamed(
      LgtmRoutes.signUp,
      arguments: const SignUpArgs(inviteCode: 'vYzA1'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Invite vYzA1 applied'), findsOneWidget);
  });
}
