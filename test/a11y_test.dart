import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/groups_store.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/app/session.dart';
import 'package:lgtm/screens/auth/login_screen.dart';
import 'package:lgtm/screens/groups/group_detail_screen.dart';
import 'package:lgtm/screens/groups/groups_hub_screen.dart';
import 'package:lgtm/screens/profile/profile_screen.dart';
import 'package:lgtm/widgets/lgtm_card.dart';
import 'package:lgtm/widgets/lgtm_inline_error.dart';
import 'package:lgtm/widgets/lgtm_text_field.dart';
import 'package:lgtm/widgets/lgtm_winner_row.dart';
import 'package:lgtm/widgets/states/lgtm_empty_state.dart';
import 'package:lgtm/widgets/states/lgtm_loading_state.dart';

/// A window at a given size, with optional text scaling and a simulated
/// on screen keyboard.
void useWindow(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  double keyboardHeight = 0,
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Scrolls a lazily built list until [finder] is on screen, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tapTo(tester, finder);
}

Future<void> tapTo(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// A session that is already signed in, with no fake waiting.
Future<LgtmSession> signedIn(WidgetTester tester) async {
  final session = LgtmSession(
    restoreDelay: Duration.zero,
    authDelay: Duration.zero,
  );
  await tester.runAsync(
    () => session.signIn(email: 'purva@example.com', password: 'password123'),
  );
  return session;
}

/// The signed in app, opened on [route].
Future<void> openApp(
  WidgetTester tester, {
  String route = LgtmRoutes.groups,
  LgtmGroupsStore? store,
}) async {
  await tester.pumpWidget(
    LgtmApp(
      initialRoute: route,
      session: await signedIn(tester),
      groupsStore: store ?? LgtmGroupsStore(delay: Duration.zero),
    ),
  );
  await tester.pump();
  await pumpUntil(tester, find.byType(GroupsHubScreen));
  await pumpUntil(tester, find.text('My Groups'));
}

const _longName = 'The Very Long Roommates Who Never Agree On Anything At All';

void main() {
  group('accessibility', () {
    testWidgets('icon only controls carry a label', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      useWindow(tester);
      await openApp(tester);

      // Menu, avatar and both built nav tabs.
      for (final label in ['Open menu', 'Your profile', 'Groups', 'Profile']) {
        expect(
          find.bySemanticsLabel(label),
          findsWidgets,
          reason: 'no semantics label for "$label"',
        );
      }

      handle.dispose();
    });

    testWidgets('past winners are announced as one phrase', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      useWindow(tester);
      await openApp(tester);

      final row = find.byType(LgtmWinnerRow).first;
      await tester.scrollUntilVisible(row, 200);
      await tester.pump();

      final semantics = tester.getSemantics(row);
      expect(semantics.label, contains('Taco Bell'));

      handle.dispose();
    });

    testWidgets('form fields are announced by their label, not the hint', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      useWindow(tester);
      await openApp(tester, route: LgtmRoutes.joinGroup);

      expect(find.byType(LgtmTextField), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Group Code')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a validation error is a live region', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      useWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.login,
          session: LgtmSession(restoreDelay: Duration.zero),
        ),
      );
      await tester.pump();
      await tapTo(tester, find.text('Sign in'));

      expect(find.byType(LgtmInlineError), findsWidgets);
      final error = tester.getSemantics(find.byType(LgtmInlineError).first);
      expect(
        error.flagsCollection.isLiveRegion,
        Tristate.isTrue.toBoolOrNull(),
      );
      expect(error.label, isNotEmpty);

      handle.dispose();
    });

    testWidgets('screen titles are marked as headings', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      useWindow(tester);
      await openApp(tester);

      final heading = tester.getSemantics(find.text('My Groups'));
      expect(heading.flagsCollection.isHeader, Tristate.isTrue.toBoolOrNull());

      handle.dispose();
    });
  });

  group('keyboard', () {
    testWidgets('Enter in the last field signs in', (
      WidgetTester tester,
    ) async {
      useWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.login,
          session: LgtmSession(
            restoreDelay: Duration.zero,
            authDelay: Duration.zero,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'purva@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(GroupsHubScreen), findsOneWidget);
    });

    testWidgets('Next moves focus from email to password', (
      WidgetTester tester,
    ) async {
      useWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.login,
          session: LgtmSession(restoreDelay: Duration.zero),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'purva@example.com');
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Whatever is typed next has to land in the password field, not the
      // email one, which is what "next" means.
      tester.testTextInput.enterText('password123');
      await tester.pump();

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.controller!.text, 'purva@example.com');
      expect(fields.last.controller!.text, 'password123');
    });

    testWidgets('the focused field stays above the keyboard', (
      WidgetTester tester,
    ) async {
      useWindow(tester, keyboardHeight: 320);
      await openApp(tester, route: LgtmRoutes.createGroup);

      await tester.tap(find.byType(TextField));
      await tester.pump();

      final field = tester.getRect(find.byType(TextField));
      expect(field.bottom, lessThanOrEqualTo(844 - 320));
      expect(field.top, greaterThanOrEqualTo(0));
    });
  });

  group('responsive', () {
    for (final size in const [Size(320, 568), Size(430, 932)]) {
      for (final textScale in const [1.0, 1.5]) {
        final name =
            '${size.width.toInt()}pt wide at ${textScale.toStringAsFixed(1)}x text';

        testWidgets('$name lays out every screen without overflowing', (
          WidgetTester tester,
        ) async {
          useWindow(tester, size: size, textScale: textScale);
          await openApp(tester);

          // Walk the whole flow so every screen is laid out at this size.
          await tapTo(tester, find.text('Profile'));
          expect(find.byType(ProfileScreen), findsOneWidget);

          await tapTo(tester, find.text('Groups'));
          await scrollAndTap(tester, find.text('Join by Code'));
          expect(find.text('Join a Group'), findsOneWidget);

          await tapTo(tester, find.byTooltip('Back to My Groups'));
          await scrollAndTap(tester, find.text('Create Group'));
          expect(find.text('Create a Group'), findsOneWidget);

          await tapTo(tester, find.byTooltip('Back to My Groups'));
          await scrollAndTap(tester, find.text('Roommates'));
          expect(find.byType(GroupDetailScreen), findsOneWidget);
        });
      }
    }

    testWidgets('the loading state fits a small phone at 1.5x text', (
      WidgetTester tester,
    ) async {
      useWindow(tester, size: const Size(320, 568), textScale: 1.5);

      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.groups,
          session: await signedIn(tester),
          groupsStore: LgtmGroupsStore(
            delay: const Duration(milliseconds: 400),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LgtmLoadingState), findsOneWidget);

      // Let the fake load finish so no timer is left pending at teardown.
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the empty state fits a small phone at 1.5x text', (
      WidgetTester tester,
    ) async {
      useWindow(tester, size: const Size(320, 568), textScale: 1.5);

      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.groups,
          session: await signedIn(tester),
          groupsStore: LgtmGroupsStore(delay: Duration.zero, seed: const []),
        ),
      );
      await tester.pump();
      await pumpUntil(tester, find.byType(LgtmEmptyState));

      expect(find.byType(LgtmEmptyState), findsOneWidget);
    });

    testWidgets('a long group name is truncated instead of growing the card', (
      WidgetTester tester,
    ) async {
      useWindow(tester);

      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.groups,
          session: await signedIn(tester),
          groupsStore: LgtmGroupsStore(
            delay: Duration.zero,
            seed: [
              const LgtmGroup(
                id: 'g1',
                name: _longName,
                kind: LgtmGroupKind.home,
                inviteCode: 'vYzA1',
                members: [],
                sessions: [],
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await pumpUntil(tester, find.text(_longName));

      final name = tester.widget<Text>(find.text(_longName));
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);

      // And the card stays the height it is designed at.
      expect(tester.getSize(find.byType(LgtmCardHeader)).height, lessThan(40));
    });
  });
}
