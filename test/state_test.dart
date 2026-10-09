import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/app/groups_store.dart';
import 'package:lgtm/app/session.dart';

void main() {
  group('the session asks a repository, not the network', () {
    test(
      'a sign in goes through the repository and lands as signed in',
      () async {
        final repository = _FakeAuth();
        final session = LgtmSession(repository: repository);

        final signedIn = await session.signIn(
          email: 'purva@example.com',
          password: 'password123',
        );

        expect(signedIn, isTrue);
        expect(repository.calls, ['signIn']);
        expect(session.isSignedIn, isTrue);
        expect(session.user?.email, 'purva@example.com');
        expect(session.error, isNull);
      },
    );

    test('a restore that finds nobody resolves signed out', () async {
      final session = LgtmSession(repository: _FakeAuth());

      await session.restore();

      expect(session.status, AuthStatus.signedOut);
      expect(session.isSignedIn, isFalse);
    });

    test('a restore that finds somebody goes straight in', () async {
      final repository = _FakeAuth(restored: _purva);
      final session = LgtmSession(repository: repository);

      await session.restore();

      expect(session.isSignedIn, isTrue);
      expect(session.user?.displayName, 'Purva');
    });

    test(
      'a rejected credential explains itself and stays signed out',
      () async {
        final repository = _FakeAuth(failure: 'That password does not match.');
        final session = LgtmSession(repository: repository);

        final signedIn = await session.signIn(
          email: 'purva@example.com',
          password: 'wrong',
        );

        expect(signedIn, isFalse);
        expect(session.isSignedIn, isFalse);
        expect(session.user, isNull);
        expect(session.error, 'That password does not match.');

        // Editing the form clears it.
        session.clearError();
        expect(session.error, isNull);
      },
    );

    test('a rename writes to the repository and keeps the uid', () async {
      final repository = _FakeAuth(restored: _purva);
      final session = LgtmSession(repository: repository);
      await session.restore();

      expect(await session.updateDisplayName('  Purva P  '), isTrue);

      expect(repository.renames, ['Purva P']);
      expect(session.user?.uid, 'u1');
      expect(session.user?.displayName, 'Purva P');
    });

    test('a rename with nobody signed in cannot invent a session', () async {
      final session = LgtmSession(repository: _FakeAuth());

      expect(await session.updateDisplayName('Purva'), isFalse);
      expect(session.isSignedIn, isFalse);
    });

    test('signing out clears the person, even if the write failed', () async {
      final session = LgtmSession(repository: _FakeAuth(restored: _purva));
      await session.restore();

      await session.signOut();

      expect(session.isSignedIn, isFalse);
      expect(session.user, isNull);
    });
  });

  group('the groups store asks a repository', () {
    test('the hub list comes from the read, not from the seed', () async {
      final store = LgtmGroupsStore(
        repository: _FakeGroups([_roommates, _squad]),
      );

      expect(store.groups, isEmpty, reason: 'nothing is known until it loads');

      await store.load();

      expect(store.isReady, isTrue);
      expect(store.groups.map((group) => group.name), [
        'Roommates',
        'Hackathon Squad',
      ]);
    });

    test('a read that fails still ends the loading state', () async {
      final store = LgtmGroupsStore(
        repository: _FakeGroups([], failure: 'Cannot reach the server.'),
      );

      await store.load();

      expect(store.isReady, isTrue);
      expect(store.error, 'Cannot reach the server.');
      expect(store.groups, isEmpty);
    });

    test('a created group goes on top and is returned to open', () async {
      final repository = _FakeGroups([_roommates]);
      final store = LgtmGroupsStore(repository: repository);
      await store.load();

      final created = await store.createGroup(name: '  Study Buddies  ');

      expect(store.groups.first.id, created.id);
      expect(store.groups.first.name, 'Study Buddies');
      expect(store.groups.first.ownerId, store.currentMember.id);
      expect(store.groups.first.members.single.id, store.currentMember.id);
      expect(store.isBusy, isFalse);
      expect(repository.membersSeen, [store.currentMember.id]);
    });

    test(
      'a join puts a new group on top and leaves an old one alone',
      () async {
        final repository = _FakeGroups([_squad, _roommates]);
        final store = LgtmGroupsStore(
          repository: repository,
          currentMember: _purvaMember,
        );
        await store.load();

        expect(await store.joinWithCode(' vyzA1 '), isTrue);

        // Roommates moved to the top because the member just joined it.
        expect(store.groups.first.id, 'g1');
        expect(store.isMember(store.groups.first), isTrue);
        expect(store.isBusy, isFalse);

        expect(await store.joinWithCode(' x7ZA1 '), isTrue);
        // Hackathon Squad was already joined, so it keeps its place.
        expect(store.groups.map((group) => group.id), ['g1', 'g2']);
      },
    );

    test('a code nobody has explains itself', () async {
      final store = LgtmGroupsStore(repository: _FakeGroups([_roommates]));
      await store.load();

      expect(await store.joinWithCode('ZZZZZ'), isFalse);
      expect(store.error, contains('could not find a group'));
      expect(store.isBusy, isFalse);
    });

    test('the store hands out its list as read only', () async {
      final store = LgtmGroupsStore(repository: _FakeGroups([_roommates]));
      await store.load();

      expect(() => store.groups.add(_squad), throwsUnsupportedError);
      expect(store.groupById('nope'), isNull);
      expect(store.groupById('g1')?.name, 'Roommates');
    });
  });

  group('provider', () {
    testWidgets('the scope is where screens get the state from', (
      WidgetTester tester,
    ) async {
      final session = LgtmSession(repository: _FakeAuth());
      addTearDown(session.dispose);

      await tester.pumpWidget(
        LgtmSessionScope(
          session: session,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Text(
                '${LgtmSessionScope.of(context).status.name} '
                '${LgtmSessionScope.read(context).status.name}',
              ),
            ),
          ),
        ),
      );

      expect(find.text('unknown unknown'), findsOneWidget);
    });

    testWidgets('a screen rebuilds when the state changes', (
      WidgetTester tester,
    ) async {
      final session = LgtmSession(repository: _FakeAuth());
      addTearDown(session.dispose);
      var builds = 0;

      await tester.pumpWidget(
        LgtmSessionScope(
          session: session,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                final signedIn = LgtmSessionScope.of(context).isSignedIn;
                builds++;
                return Text(signedIn ? 'in' : 'out');
              },
            ),
          ),
        ),
      );
      expect(find.text('out'), findsOneWidget);

      await session.signIn(email: 'purva@example.com', password: 'password123');
      await tester.pump();

      expect(find.text('in'), findsOneWidget);
      expect(builds, greaterThan(1), reason: 'a listen, not a read');
    });

    testWidgets('the nearest scope wins, so a test can swap the state', (
      WidgetTester tester,
    ) async {
      final outer = LgtmGroupsStore(repository: _FakeGroups([_roommates]));
      final inner = LgtmGroupsStore(repository: _FakeGroups([_squad]));
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);

      await tester.pumpWidget(
        LgtmGroupsScope(
          store: outer,
          child: MaterialApp(
            home: LgtmGroupsScope(
              store: inner,
              child: Builder(
                builder: (context) =>
                    Text('${LgtmGroupsScope.of(context).groups.length}'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);

      await tester.runAsync(() async => inner.load());
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}

const _purva = LgtmUser(
  uid: 'u1',
  displayName: 'Purva',
  email: 'purva@example.com',
);

const _purvaMember = LgtmMember(
  id: 'u1',
  displayName: 'Purva',
  avatarColor: Color(0xFF4A4A4A),
);

const _roommates = LgtmGroup(
  id: 'g1',
  name: 'Roommates',
  kind: LgtmGroupKind.home,
  inviteCode: 'vYzA1',
  ownerId: 'u0',
);

const _squad = LgtmGroup(
  id: 'g2',
  name: 'Hackathon Squad',
  kind: LgtmGroupKind.work,
  inviteCode: 'x7ZA1',
  ownerId: 'u0',
  members: [_purvaMember],
);

/// An auth repository that answers from a script instead of Firebase.
class _FakeAuth implements LgtmAuthRepository {
  _FakeAuth({this.restored, this.failure});

  final LgtmUser? restored;
  final String? failure;

  final List<String> calls = [];
  final List<String> renames = [];

  @override
  Future<LgtmUser?> restore() async {
    calls.add('restore');
    return restored;
  }

  @override
  Future<LgtmUser> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn');
    if (failure != null) throw LgtmAuthException(failure!);
    return _purva;
  }

  @override
  Future<LgtmUser?> signInWithGoogle() async {
    calls.add('signInWithGoogle');
    if (failure != null) throw LgtmAuthException(failure!);
    return _purva;
  }

  @override
  Future<LgtmUser> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    calls.add('signUp');
    if (failure != null) throw LgtmAuthException(failure!);
    return _purva;
  }

  @override
  Future<void> signOut() async => calls.add('signOut');

  @override
  Future<void> updateDisplayName(String displayName) async {
    renames.add(displayName.trim());
    if (failure != null) throw LgtmAuthException(failure!);
  }
}

/// A groups repository holding [groups] in memory, with no delays.
class _FakeGroups implements LgtmGroupsRepository {
  _FakeGroups(this.groups, {this.failure});

  final List<LgtmGroup> groups;
  final String? failure;

  final List<String> membersSeen = [];

  @override
  Future<List<LgtmGroup>> loadGroups({required LgtmMember member}) async {
    membersSeen.add(member.id);
    if (failure != null) throw LgtmGroupsException(failure!);
    return List.unmodifiable(groups);
  }

  @override
  Future<LgtmGroup> createGroup({
    required String name,
    required LgtmMember member,
  }) async {
    if (failure != null) throw LgtmGroupsException(failure!);
    final created = LgtmGroup(
      id: 'g${groups.length + 1}',
      name: name.trim(),
      kind: LgtmGroupKind.home,
      inviteCode: 'NEW01',
      ownerId: member.id,
      members: [member],
    );
    groups.insert(0, created);
    return created;
  }

  @override
  Future<LgtmGroup> joinWithCode({
    required String code,
    required LgtmMember member,
  }) async {
    if (failure != null) throw LgtmGroupsException(failure!);

    final wanted = code.trim().toLowerCase();
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.inviteCode.toLowerCase() != wanted) continue;
      if (group.members.any((inGroup) => inGroup.id == member.id)) return group;

      // A real repository keeps the join, so the next call sees it.
      final joined = group.copyWith(members: [...group.members, member]);
      groups[i] = joined;
      return joined;
    }
    throw const LgtmGroupsException(
      'We could not find a group with that code. Check it and try again.',
    );
  }
}
