import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/app.dart';
import 'package:lgtm/app/groups_store.dart';
import 'package:lgtm/app/router.dart';
import 'package:lgtm/app/theme.dart';
import 'package:lgtm/screens/groups/create_group_screen.dart';
import 'package:lgtm/screens/groups/group_detail_screen.dart';
import 'package:lgtm/screens/groups/groups_hub_screen.dart';
import 'package:lgtm/screens/groups/join_group_screen.dart';
import 'package:lgtm/widgets/lgtm_card.dart';
import 'package:lgtm/widgets/lgtm_pill.dart';

/// The app is a 390pt column, so the tests are too.
void usePhoneWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps forward until [finder] matches. The store waits on timers.
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// A tap that pushes a route needs several frames: one to build the new route
/// and enough ticks of the transition to take the screen underneath offstage,
/// so later finders only see the screen on top.
Future<void> tapTo(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

LgtmGroupsStore fastStore({List<LgtmGroup>? seed, LgtmMember? member}) =>
    LgtmGroupsStore(delay: Duration.zero, seed: seed, currentMember: member);

/// Pumps the hub and waits for the groups to land.
Future<LgtmGroupsStore> openHub(
  WidgetTester tester, {
  LgtmGroupsStore? store,
}) async {
  final groups = store ?? fastStore();
  usePhoneWindow(tester);
  await tester.pumpWidget(
    LgtmApp(initialRoute: LgtmRoutes.groups, groupsStore: groups),
  );
  await tester.pump();
  await pumpUntil(tester, find.byType(GroupsHubScreen));
  await pumpUntil(tester, find.text('My Groups'));
  return groups;
}

const _roommates = LgtmGroup(
  id: 'g1',
  name: 'Roommates',
  kind: LgtmGroupKind.home,
  inviteCode: 'vYzA1',
  members: [
    LgtmMember(id: 'u0', displayName: 'Purva', avatarColor: Color(0xFF4A4A4A)),
    LgtmMember(id: 'u1', displayName: 'Nikhil', avatarColor: Color(0xFF2F5D5B)),
  ],
  sessions: [
    LgtmGroupSession(
      id: 's1',
      activity: 'Dinner',
      winnerName: 'Taco Bell',
      winnerIcon: Icons.lunch_dining,
      date: '12 Mar',
    ),
  ],
);

const _squad = LgtmGroup(
  id: 'g2',
  name: 'Squad',
  kind: LgtmGroupKind.work,
  inviteCode: 'x7ZA1',
  members: [
    LgtmMember(id: 'u0', displayName: 'Purva', avatarColor: Color(0xFF4A4A4A)),
  ],
  sessions: [],
);

const _outsider = LgtmMember(
  id: 'u9',
  displayName: 'Zoya',
  avatarColor: Color(0xFF5B4A3A),
);

void main() {
  group('groups store', () {
    test('starts not ready and empty, then holds the mock groups', () async {
      final store = fastStore();

      // Nothing is known until the read lands, so a screen cannot show a
      // half empty hub.
      expect(store.isReady, isFalse);
      expect(store.groups, isEmpty);

      await store.load();

      expect(store.isReady, isTrue);
      expect(store.groups.map((group) => group.name), [
        'Roommates',
        'Hackathon Squad',
      ]);
    });

    test('load flips the ready flag once', () async {
      final store = fastStore();

      await store.load();
      await store.load();

      expect(store.isReady, isTrue);
    });

    test('an empty seed gives the hub nothing to show', () {
      expect(fastStore(seed: const []).groups, isEmpty);
    });

    test('creating a group puts it on top with a fresh invite code', () async {
      final store = fastStore(seed: const []);

      final group = await store.createGroup(name: '  Study Buddies  ');

      expect(store.groups.single.name, 'Study Buddies');
      expect(group.inviteCode, matches(RegExp(r'^[A-Z2-9]{5}$')));
      expect(group.members.single.id, store.currentMember.id);
      expect(store.groupById(group.id), same(group));
    });

    test('joining with a code matches it however it was typed', () async {
      final store = fastStore(seed: const [_roommates], member: _outsider);

      final joined = await store.joinWithCode(' vyza1 ');

      expect(joined, isTrue);
      expect(store.isMember(store.groups.single), isTrue);
    });

    test('joining with an unknown code explains itself', () async {
      final store = fastStore(seed: const [_roommates], member: _outsider);

      final joined = await store.joinWithCode('ZZZZZ');

      expect(joined, isFalse);
      expect(store.error, contains('could not find a group'));
    });

    test('joining a group you are already in does not add you twice', () async {
      final store = fastStore(seed: const [_roommates]);

      expect(await store.joinWithCode('vYzA1'), isTrue);
      expect(store.groups.single.members.length, 2);
    });

    test('the invite link is built from the code', () {
      expect(_roommates.inviteLink, 'lgtm.app/invite/vYzA1');
    });

    test('the hub card shows the three most recent wins', () {
      expect(_roommates.recentWinners.single.winnerName, 'Taco Bell');
    });
  });

  group('my groups hub', () {
    testWidgets('shows a loading state, then the groups and past winners', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(initialRoute: LgtmRoutes.groups, groupsStore: fastStore()),
      );
      await tester.pump();

      expect(find.text('Loading your groups...'), findsOneWidget);

      await pumpUntil(tester, find.text('My Groups'));

      expect(find.text('Loading your groups...'), findsNothing);
      expect(find.text('Roommates'), findsOneWidget);
      expect(find.text('Hackathon Squad'), findsOneWidget);
      expect(find.text('ACTIVE MEMBERS'), findsOneWidget);
      expect(find.text('PAST WINNERS'), findsOneWidget);
      expect(find.text('Taco Bell'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Start New Session (Dinner)'),
        300,
      );
      expect(find.text('Start New Session (Dinner)'), findsOneWidget);

      // The Create and Join row sits below the CTA, so it needs its own scroll.
      await tester.scrollUntilVisible(find.text('Join by Code'), 200);
      expect(find.text('Create Group'), findsOneWidget);
      expect(find.text('Join by Code'), findsOneWidget);
    });

    testWidgets('an empty account gets the empty state and a way out', (
      WidgetTester tester,
    ) async {
      await openHub(tester, store: fastStore(seed: const []));

      expect(find.text('No groups yet'), findsOneWidget);

      await tapTo(tester, find.text('Create Group'));

      expect(find.byType(CreateGroupScreen), findsOneWidget);
    });

    testWidgets('a group card opens its detail screen', (
      WidgetTester tester,
    ) async {
      await openHub(tester);

      await tapTo(tester, find.text('Roommates'));

      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('lgtm.app/invite/vYzA1'), findsOneWidget);
      expect(find.text('Create Group'), findsNothing);
    });

    testWidgets('every collapsed group card uses the 72pt pill metrics', (
      WidgetTester tester,
    ) async {
      await openHub(tester, store: fastStore(seed: [_roommates, _squad]));

      final cards = find.byType(LgtmCard);
      // The first group gets the tall card, the second the collapsed one.
      expect(cards, findsNWidgets(2));

      final collapsed = cards.last;
      expect(tester.getSize(collapsed).height, 72);

      final icon = find.descendant(
        of: collapsed,
        matching: find.byType(LgtmIconTile),
      );
      expect(tester.getSize(icon), const Size.square(40));

      // The 1pt card border sits outside the padding, so 16pt of padding is
      // 17pt from the drawn edge.
      final circle = tester.getRect(icon);
      final card = tester.getRect(collapsed);
      expect(circle.left - card.left, 17);
      expect(card.top - circle.top, closeTo(circle.bottom - card.bottom, 0.5));

      final name = find.descendant(of: collapsed, matching: find.text('Squad'));
      expect(
        tester.getSize(name).height,
        lessThan(tester.getSize(collapsed).height),
      );

      final chevron = find.descendant(
        of: collapsed,
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(tester.getSize(chevron), const Size.square(18));
      expect(card.right - tester.getRect(chevron).right, closeTo(21, 0.5));
    });

    testWidgets('the join action opens the join form', (
      WidgetTester tester,
    ) async {
      await openHub(tester);

      await tester.scrollUntilVisible(find.text('Join by Code'), 300);
      await tapTo(tester, find.text('Join by Code'));

      expect(find.byType(JoinGroupScreen), findsOneWidget);
    });

    testWidgets('tabs that are not built yet say so', (
      WidgetTester tester,
    ) async {
      await openHub(tester);

      await tester.tap(find.text('Swipe'));
      await tester.pump();

      expect(find.text('The swipe flow is not built yet.'), findsOneWidget);
    });
  });

  group('create group', () {
    testWidgets('an empty name is called out in plain language', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.createGroup,
          groupsStore: fastStore(seed: const []),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Create Group'));
      await tester.pump();

      expect(find.text('Give your group a name.'), findsOneWidget);
    });

    testWidgets('a new group opens on its own invite code', (
      WidgetTester tester,
    ) async {
      final store = fastStore(seed: const []);
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(initialRoute: LgtmRoutes.createGroup, groupsStore: store),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Study Buddies');
      await tapTo(tester, find.text('Create Group'));

      expect(find.byType(CreateGroupScreen), findsNothing);
      expect(find.byType(GroupDetailScreen), findsOneWidget);
      expect(find.text('Study Buddies'), findsOneWidget);
      expect(find.textContaining('lgtm.app/invite/'), findsOneWidget);
      expect(store.groups.single.name, 'Study Buddies');
    });

    testWidgets('the join link swaps this form for the join form', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.createGroup,
          groupsStore: fastStore(seed: const []),
        ),
      );
      await tester.pump();

      await tapTo(tester, find.text('Have a code? Join a group instead'));

      expect(find.byType(CreateGroupScreen), findsNothing);
      expect(find.byType(JoinGroupScreen), findsOneWidget);
    });
  });

  group('join group', () {
    testWidgets('a code that cannot be a code is explained', (
      WidgetTester tester,
    ) async {
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(
          initialRoute: LgtmRoutes.joinGroup,
          groupsStore: fastStore(seed: const [_roommates], member: _outsider),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'no');
      await tester.tap(find.text('Join Group'));
      await tester.pump();

      expect(
        find.text('Codes are 4 to 12 letters or numbers.'),
        findsOneWidget,
      );
    });

    testWidgets('a code nobody has is explained', (WidgetTester tester) async {
      final store = fastStore(seed: const [_roommates], member: _outsider);
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(initialRoute: LgtmRoutes.joinGroup, groupsStore: store),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'ZZZZZ');
      await tester.tap(find.text('Join Group'));
      await pumpUntil(tester, find.textContaining('could not find a group'));

      expect(find.byType(JoinGroupScreen), findsOneWidget);
    });

    testWidgets('a good code puts the group on the hub', (
      WidgetTester tester,
    ) async {
      final store = fastStore(seed: const [_roommates], member: _outsider);
      usePhoneWindow(tester);
      await tester.pumpWidget(
        LgtmApp(initialRoute: LgtmRoutes.groups, groupsStore: store),
      );
      await tester.pump();
      await pumpUntil(tester, find.text('My Groups'));
      await tester.scrollUntilVisible(find.text('Join by Code'), 300);

      await tapTo(tester, find.text('Join by Code'));
      await tester.enterText(find.byType(TextField), 'vYzA1');
      await tester.tap(find.text('Join Group'));
      await pumpUntil(tester, find.text('My Groups'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(JoinGroupScreen), findsNothing);
      expect(find.byType(GroupsHubScreen), findsOneWidget);
      expect(find.text('Roommates'), findsOneWidget);
      expect(store.isMember(store.groups.single), isTrue);
    });
  });

  group('group detail', () {
    testWidgets('lists every member and marks you', (
      WidgetTester tester,
    ) async {
      await openHub(tester, store: fastStore(seed: const [_roommates]));

      await tapTo(tester, find.text('Roommates'));
      await tester.scrollUntilVisible(find.text('MEMBERS'), 200);

      expect(find.text('Purva'), findsOneWidget);
      expect(find.text('Nikhil'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('shows what the group already decided', (
      WidgetTester tester,
    ) async {
      await openHub(tester, store: fastStore(seed: const [_roommates]));

      await tapTo(tester, find.text('Roommates'));
      await tester.scrollUntilVisible(find.text('PAST SESSIONS'), 200);

      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Taco Bell'), findsOneWidget);
      expect(find.text('12 Mar'), findsOneWidget);
    });

    testWidgets('a group with no sessions says so', (
      WidgetTester tester,
    ) async {
      await openHub(tester);

      await tapTo(tester, find.text('Hackathon Squad'));
      await tester.scrollUntilVisible(find.text('PAST SESSIONS'), 200);

      expect(
        find.text('No sessions yet. Start one and the result lands here.'),
        findsOneWidget,
      );
    });

    testWidgets('copying the invite link puts it on the clipboard', (
      WidgetTester tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await openHub(tester, store: fastStore(seed: const [_roommates]));

      await tapTo(tester, find.text('Roommates'));
      await tester.tap(find.byTooltip('Copy invite link'));
      await tester.pump();

      expect(copied, 'lgtm.app/invite/vYzA1');
      expect(find.text('Invite link copied.'), findsOneWidget);
    });

    testWidgets('sharing is not connected yet', (WidgetTester tester) async {
      await openHub(tester, store: fastStore(seed: const [_roommates]));

      await tapTo(tester, find.text('Roommates'));
      await tester.tap(find.byTooltip('Share invite link'));
      await tester.pump();

      expect(find.text('Sharing is not connected yet.'), findsOneWidget);
    });

    testWidgets('starting a session says the setup screen is not built', (
      WidgetTester tester,
    ) async {
      await openHub(tester, store: fastStore(seed: const [_roommates]));

      await tapTo(tester, find.text('Roommates'));
      await tester.tap(find.text('Start Session'));
      await tester.pump();

      expect(find.text('Session setup is not built yet.'), findsOneWidget);
    });

    testWidgets('a group id nobody has shows the not found state', (
      WidgetTester tester,
    ) async {
      final store = fastStore(seed: const [_roommates]);
      usePhoneWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: LgtmTheme.light,
          initialRoute: LgtmRoutes.groups,
          onGenerateInitialRoutes: (name) => [
            lgtmGenerateRoute(RouteSettings(name: name)),
          ],
          onGenerateRoute: lgtmGenerateRoute,
          builder: (context, child) =>
              LgtmGroupsScope(store: store, child: child!),
        ),
      );
      await tester.pump();

      // Route straight onto a group that is not in the store.
      Navigator.of(tester.element(find.byType(GroupsHubScreen))).pushNamed(
        LgtmRoutes.groupDetail,
        arguments: const GroupDetailArgs(groupId: 'nope'),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Group not found'), findsOneWidget);
    });
  });
}
