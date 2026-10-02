import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/theme.dart';
import 'package:lgtm/core/design_tokens.dart';
import 'package:lgtm/widgets/lgtm_buttons.dart';
import 'package:lgtm/widgets/states/lgtm_confirm_dialog.dart';
import 'package:lgtm/widgets/states/lgtm_empty_state.dart';
import 'package:lgtm/widgets/states/lgtm_error_state.dart';
import 'package:lgtm/widgets/states/lgtm_loading_state.dart';
import 'package:lgtm/widgets/states/lgtm_offline_banner.dart';

void main() {
  Future<void> pumpInApp(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        theme: LgtmTheme.light,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('loading state shows a spinner with a plain language label', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      const LgtmLoadingState(label: 'Checking your account...'),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Checking your account...'), findsOneWidget);
  });

  testWidgets('error state explains itself and offers a way out', (
    WidgetTester tester,
  ) async {
    var retried = 0;
    await pumpInApp(
      tester,
      LgtmErrorState(
        title: 'Something went wrong',
        message: 'We could not load your groups.',
        onRetry: () => retried++,
      ),
    );

    expect(find.text('We could not load your groups.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('empty state pairs the empty space with its action', (
    WidgetTester tester,
  ) async {
    var acted = 0;
    await pumpInApp(
      tester,
      LgtmEmptyState(
        title: 'No groups yet',
        message: 'Create one or join with a code.',
        actionLabel: 'Create a group',
        onAction: () => acted++,
      ),
    );

    expect(find.text('No groups yet'), findsOneWidget);
    await tester.tap(find.text('Create a group'));
    expect(acted, 1);
  });

  testWidgets('offline banner explains itself without blocking', (
    WidgetTester tester,
  ) async {
    var retried = 0;
    await pumpInApp(tester, LgtmOfflineBanner(onRetry: () => retried++));

    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('confirmation resolves true only when confirmed', (
    WidgetTester tester,
  ) async {
    bool? answer;
    await pumpInApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            answer = await LgtmConfirmDialog.show(
              context,
              title: 'Leave this group?',
              message: 'You will need a new invite code to come back.',
              confirmLabel: 'Leave',
              destructive: true,
            );
          },
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Leave this group?'), findsOneWidget);

    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });

  testWidgets('dismissing the confirmation counts as no', (
    WidgetTester tester,
  ) async {
    bool? answer;
    await pumpInApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            answer = await LgtmConfirmDialog.show(
              context,
              title: 'Sign out?',
              message: 'You can sign back in any time.',
            );
          },
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(answer, isFalse);
  });

  testWidgets('a destructive confirmation turns the confirm button red', (
    WidgetTester tester,
  ) async {
    await pumpInApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => LgtmConfirmDialog.show(
            context,
            title: 'Leave this group?',
            message: 'You will need a new invite code to come back.',
            confirmLabel: 'Leave',
            destructive: true,
          ),
          child: const Text('Open'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final confirm = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(LgtmPrimaryButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((confirm.decoration as BoxDecoration).color, LgtmColors.reject);
  });
}
