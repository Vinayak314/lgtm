import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/core/design_tokens.dart';
import 'package:lgtm/widgets/lgtm_bottom_nav.dart';
import 'package:lgtm/widgets/lgtm_logo.dart';
import 'package:lgtm/widgets/lgtm_pill.dart';
import 'package:lgtm/widgets/lgtm_top_bar.dart';

void main() {
  testWidgets('shell constrains content to the 390pt design column', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LgtmApp());
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, LgtmColors.bg);

    final canvas = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(MaterialApp),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(canvas.color, LgtmColors.bg);
  });

  testWidgets('bundled serif and sans fonts are used', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LgtmApp(initialRoute: LgtmRoutes.designPreview),
    );
    await tester.pump();

    final serif = tester.widget<Text>(find.text('LGTM').first);
    expect(serif.style!.fontFamily, 'Vollkorn');
    expect(serif.style!.fontStyle, FontStyle.italic);

    final sans = tester.widget<Text>(find.text('ACTIVE MEMBERS'));
    expect(sans.style!.fontFamily, 'PlusJakartaSans');
  });

  testWidgets('bottom nav highlights the active tab with the crimson label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LgtmApp(initialRoute: LgtmRoutes.designPreview),
    );
    await tester.pump();

    final groups = tester.widget<Text>(find.text('Groups'));
    final swipe = tester.widget<Text>(find.text('Swipe'));

    expect(groups.style!.fontWeight, FontWeight.w700);
    expect(groups.style!.fontSize, 15);
    expect(groups.style!.color, LgtmColors.primary);

    expect(swipe.style!.fontWeight, FontWeight.w500);
    expect(swipe.style!.fontSize, 13);
    expect(swipe.style!.color, LgtmColors.inkSoft);
  });

  testWidgets('logo size and colour are configurable per screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LgtmLogo(size: 46, color: LgtmColors.green)),
      ),
    );

    final logo = tester.widget<Text>(find.text('LGTM'));
    expect(logo.style!.fontSize, 46);
    expect(logo.style!.color, LgtmColors.green);
  });

  test('bottom nav has exactly four tabs in order', () {
    expect(LgtmNavTab.values, [
      LgtmNavTab.groups,
      LgtmNavTab.swipe,
      LgtmNavTab.matches,
      LgtmNavTab.profile,
    ]);
  });

  testWidgets('top bar leads with the hamburger, never a second wordmark', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LgtmApp(initialRoute: LgtmRoutes.designPreview),
    );
    await tester.pump();

    expect(find.byType(LgtmMenuButton), findsOneWidget);

    final menu = tester.widget<LgtmMenuButton>(find.byType(LgtmMenuButton));
    expect(menu.color, LgtmColors.inkMuted);
    expect(menu.size, 24);
    expect(menu.strokeWidth, 2);

    // Only the crimson centred wordmark is left in the bar.
    final wordmarks = tester.widgetList<Text>(
      find.descendant(of: find.byType(LgtmTopBar), matching: find.text('LGTM')),
    );
    expect(wordmarks, hasLength(1));
    expect(wordmarks.single.style!.color, LgtmColors.primary);
    expect(wordmarks.single.maxLines, 1);
  });

  testWidgets('icon tile keeps at least 8pt of tile around the glyph', (
    WidgetTester tester,
  ) async {
    const tile = LgtmIconTile(icon: Icons.lunch_dining);

    expect(tile.size, 36);
    expect(tile.borderRadius, LgtmRadius.pill);
    expect(tile.iconSize, 20);
    expect(tile.size - tile.iconSize, greaterThanOrEqualTo(16));
  });

  test('icon tile rejects a glyph that would fill it', () {
    expect(
      () => LgtmIconTile(icon: Icons.lunch_dining, size: 36, iconSize: 22),
      throwsAssertionError,
    );
  });

  testWidgets('the bar title sits on the true centre line', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<double> titleCentreWith({Widget? leading, Widget? trailing}) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: MaterialApp(
            home: Scaffold(
              body: LgtmTopBar(
                leading:
                    leading ??
                    const LgtmIconButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Back',
                      onPressed: _noop,
                    ),
                center: const Text('Roommates'),
                actions: [?trailing],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getCenter(find.text('Roommates')).dx;
    }

    const width = 390.0;

    // A back arrow with nothing on the right used to push the title right.
    expect(await titleCentreWith(), closeTo(width / 2, 0.5));

    // Same with a trailing action: both cells are the same width.
    expect(
      await titleCentreWith(trailing: const Icon(Icons.more_horiz)),
      closeTo(width / 2, 0.5),
    );

    // And with no leading control at all.
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: MaterialApp(
          home: Scaffold(body: LgtmTopBar(center: Text('Roommates'))),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.getCenter(find.text('Roommates')).dx,
      closeTo(width / 2, 0.5),
    );
  });

  testWidgets('header clears the status bar', (WidgetTester tester) async {
    Future<void> pumpWithPadding(double top) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: top)),
        child: const MaterialApp(home: Scaffold(body: LgtmTopBar())),
      ),
    );

    // The 1pt bottom rule sits under the 64pt content, at the bottom of the bar.
    const border = 1.0;

    // No safe area reported: the 20pt floor applies.
    await pumpWithPadding(0);
    expect(
      tester.getSize(find.byType(LgtmTopBar)).height,
      20 + LgtmLayout.topBarHeight + border,
    );

    // Real notch: the reported inset wins.
    await pumpWithPadding(44);
    expect(
      tester.getSize(find.byType(LgtmTopBar)).height,
      44 + LgtmLayout.topBarHeight + border,
    );
  });
}

void _noop() {}
