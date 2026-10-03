import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lgtm/data/groups_repository.dart';
import 'package:lgtm/models/json.dart';
import 'package:lgtm/models/user.dart';

void main() {
  group('reading payloads', () {
    test('a missing or wrongly typed field falls back instead of throwing', () {
      expect(jsonAsMap(null), isEmpty);
      expect(jsonAsMap('nonsense'), isEmpty);
      expect(jsonAsString(null, fallback: 'none'), 'none');
      expect(jsonAsString(42, fallback: 'none'), 'none');
      expect(jsonAsInt('7'), 7);
      expect(jsonAsInt(7.9), 7);
      expect(jsonAsInt('seven', fallback: 3), 3);
      expect(jsonAsBool('true'), isFalse);
      expect(jsonAsMapList(null), isEmpty);
      expect(
        jsonAsMapList([
          {'a': 1},
          'nope',
        ]),
        [
          {'a': 1},
          <String, Object?>{},
        ],
      );
    });
  });

  group('user', () {
    test('round trips through users/{uid}', () {
      const user = LgtmUser(
        uid: 'u9',
        displayName: 'Purva',
        email: 'purva@example.com',
        fcmToken: 'token',
      );

      expect(LgtmUser.fromJson('u9', user.toJson()).uid, 'u9');
      expect(LgtmUser.fromJson('u9', user.toJson()).displayName, 'Purva');
      expect(LgtmUser.fromJson('u9', user.toJson()).fcmToken, 'token');
    });

    test('the uid is the key, so it is never written twice', () {
      const user = LgtmUser(
        uid: 'u9',
        displayName: 'Purva',
        email: 'purva@example.com',
      );

      expect(user.toJson().containsKey('uid'), isFalse);
      expect(user.toJson()['name'], 'Purva');
      // No push token until notifications land, so no empty string is stored.
      expect(user.toJson().containsKey('fcmToken'), isFalse);
    });

    test('a half written profile still loads', () {
      final user = LgtmUser.fromJson('u9', {'email': 'p@example.com'});

      expect(user.displayName, 'Friend');
      expect(user.email, 'p@example.com');
      expect(user.fcmToken, isNull);
    });

    test('a users collection keeps the entries that are objects', () {
      final users = LgtmUser.listFromJson({
        'u1': {'name': 'Purva', 'email': 'p@example.com'},
        'u2': 'not a profile',
      });

      expect(users.map((user) => user.uid), ['u1']);
      expect(users.single.displayName, 'Purva');
    });

    test('a name can be made out of an address when there is not one', () {
      // An account made in the Firebase console arrives with no display name,
      // and the rules will not store an empty one, so this is what stands in.
      expect(LgtmUser.nameFromEmail('purva.s@example.com'), 'Purva S');
      expect(LgtmUser.nameFromEmail('  nikhil+test@x.co '), 'Nikhil Test');
      expect(LgtmUser.nameFromEmail('someone@x.co'), 'Someone');

      // Nothing to work from at all still gives a name, never an empty string.
      expect(LgtmUser.nameFromEmail(''), 'Friend');
      expect(LgtmUser.nameFromEmail(null), 'Friend');
      expect(LgtmUser.nameFromEmail('@example.com'), 'Friend');
      expect(LgtmUser.nameFromEmail(null, fallback: 'Guest'), 'Guest');
    });
  });

  group('member', () {
    test('an avatar colour comes from the id and never moves', () {
      expect(avatarColorFor('u1'), avatarColorFor('u1'));
      expect(avatarColorFor('u1'), isNot(avatarColorFor('u2')));
      expect(
        _avatarPalette.contains(avatarColorFor('some-longer-uid')),
        isTrue,
      );
    });

    test('is built from a profile, and writes back a name and an id', () {
      final member = LgtmMember.fromUser(
        const LgtmUser(uid: 'u1', displayName: 'Nikhil', email: 'n@x.com'),
      );

      expect(member.id, 'u1');
      expect(member.displayName, 'Nikhil');
      expect(member.avatarColor, avatarColorFor('u1'));
      expect(member.toJson(), {'id': 'u1', 'name': 'Nikhil'});
    });

    test('an empty id still gets a colour rather than crashing', () {
      final member = LgtmMember.fromJson({'name': 'Dev'});

      expect(member.displayName, 'Dev');
      expect(member.avatarColor, isA<Color>());
    });
  });

  group('group', () {
    test('round trips through groups/{gid}', () {
      const group = LgtmGroup(
        id: 'g1',
        name: 'Roommates',
        kind: LgtmGroupKind.work,
        inviteCode: 'vYzA1',
        ownerId: 'u0',
        activeSessionId: 's9',
        members: [
          LgtmMember(id: 'u0', displayName: 'Purva', avatarColor: grey),
          LgtmMember(id: 'u1', displayName: 'Nikhil', avatarColor: grey),
        ],
      );

      final read = LgtmGroup.fromJson(
        'g1',
        group.toJson(),
        members: group.members,
      );

      expect(read.id, 'g1');
      expect(read.name, 'Roommates');
      expect(read.kind, LgtmGroupKind.work);
      expect(read.inviteCode, 'vYzA1');
      expect(read.ownerId, 'u0');
      expect(read.activeSessionId, 's9');
      expect(read.memberIds, ['u0', 'u1']);
    });

    test('writes members as the uid map the rules check', () {
      const group = LgtmGroup(
        id: 'g1',
        name: 'Roommates',
        kind: LgtmGroupKind.home,
        inviteCode: 'vYzA1',
        ownerId: 'u0',
        members: [
          LgtmMember(id: 'u0', displayName: 'Purva', avatarColor: grey),
        ],
      );

      expect(group.toJson()['members'], {'u0': true});
    });

    test('"no session running" is written as null, not left out', () {
      const group = LgtmGroup(
        id: 'g1',
        name: 'Roommates',
        kind: LgtmGroupKind.home,
        inviteCode: 'vYzA1',
      );

      expect(group.toJson().containsKey('activeSession'), isTrue);
      expect(group.toJson()['activeSession'], isNull);
      expect(group.hasActiveSession, isFalse);
    });

    test('an unknown kind or an empty record still loads', () {
      final group = LgtmGroup.fromJson('g1', {'kind': 'gym', 'code': 'abc'});

      expect(group.kind, LgtmGroupKind.home, reason: 'falls back to home');
      expect(group.name, 'Group');
      expect(group.inviteLink, 'lgtm.app/invite/abc');
      expect(group.hasWinners, isFalse);
      expect(group.recentWinners, isEmpty);
    });
  });

  group('finished session', () {
    test('round trips and derives the placeholder glyph from the activity', () {
      const session = LgtmGroupSession(
        id: 's1',
        activity: 'Dinner',
        winnerName: 'Taco Bell',
        winnerIcon: Icons.lunch_dining,
        date: '12 Mar',
      );

      final read = LgtmGroupSession.fromJson('s1', session.toJson());

      expect(read.id, 's1');
      expect(read.winnerName, 'Taco Bell');
      expect(read.date, '12 Mar');
      expect(read.winnerIcon, Icons.lunch_dining);
    });

    test('every activity maps to a glyph, so cards cannot end up blank', () {
      for (final activity in ['Dinner', 'Lunch', 'Coffee', 'Movie', 'Trip']) {
        expect(sessionIconFor(activity), isA<IconData>());
      }
      expect(sessionIconFor('Lunch'), Icons.ramen_dining);
      expect(sessionIconFor('Anything else'), Icons.fastfood);
    });

    test('a sessions collection keeps the entries that are objects', () {
      final sessions = LgtmGroupSession.listFromJson({
        's1': {
          'activity': 'Dinner',
          'winnerName': 'Taco Bell',
          'date': '12 Mar',
        },
        's2': null,
      });

      expect(sessions.single.id, 's1');
      expect(sessions.single.winnerIcon, Icons.lunch_dining);
    });
  });
}

const grey = Color(0xFF4A4A4A);

const _avatarPalette = [
  Color(0xFF4A4A4A),
  Color(0xFF2F5D5B),
  Color(0xFF4B3F63),
  Color(0xFF5B4A3A),
  Color(0xFF3F5A46),
  Color(0xFF6B4A4A),
];
