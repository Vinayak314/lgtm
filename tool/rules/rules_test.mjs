// Checks database.rules.json against the Realtime Database emulator, which is
// the only way to prove a rule denies something rather than only looking like
// it should.
//
//   cd tool/rules && npm install && cd ../..
//   firebase emulators:start --only database --project lgtm-app
//   node tool/rules/rules_test.mjs
//
// The emulator loads database.rules.json through firebase.json, so this runs
// exactly the rules that get deployed.

import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(here, '..', '..');

const host = process.env.FIREBASE_DATABASE_EMULATOR_HOST ?? '127.0.0.1';
const port = Number(process.env.FIREBASE_DATABASE_EMULATOR_PORT ?? 9000);

const testEnv = await initializeTestEnvironment({
  projectId: 'lgtm-app',
  database: {
    host,
    port,
    rules: readFileSync(join(projectRoot, 'database.rules.json'), 'utf8'),
  },
});

// One context per account, reused for the whole run: a Database handle can only
// be pointed at the emulator once, so the same uid has to keep the same handle.
const handles = new Map();

function as(uid) {
  const known = handles.get(uid);
  if (known) return known;
  const database =
    uid === null
      ? testEnv.unauthenticatedContext().database()
      : testEnv.authenticatedContext(uid).database();
  const handle = { uid, database };
  handles.set(uid, handle);
  return handle;
}

/// Writes with the rules switched off: these are fixtures, not the behaviour
/// under test.
const seed = (write) =>
  testEnv.withSecurityRulesDisabled((context) => write(context.database()));

/// A signed in account, with the profile the app would have written on sign up.
async function signUp(name) {
  const uid = `u${Math.random().toString(36).slice(2, 10)}`;
  await seed((database) =>
    database.ref(`users/${uid}`).set({ name, email: `${uid}@example.com` }),
  );
  return as(uid);
}

/// The record createGroup writes.
const group = (code, ownerId) => ({
  name: 'Roommates',
  code,
  ownerId,
  kind: 'home',
  createdAt: 1700000000000,
  activeSession: null,
  members: { [ownerId]: true },
});

/// A group id shaped like the ones push() hands out: '-N' then 19 characters
/// from the push alphabet, 21 in total. Tests use this instead of 'g1' so a
/// rule that only tolerates toy ids cannot pass.
const pushId = () => {
  const alphabet =
    '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
  let id = '-N';
  for (let i = 0; i < 19; i += 1) {
    id += alphabet[Math.floor(Math.random() * alphabet.length)];
  }
  return id;
};

/// The record the session engine writes when a host starts a session.
const session = (groupId, hostId) => ({
  groupId,
  hostId,
  status: 'lobby',
  category: null,
  radius: 5000,
  createdAt: 1700000000000,
  cards: [],
  participants: { [hostId]: true },
});

const passed = [];
const failed = [];

async function it(name, body) {
  await testEnv.clearDatabase();
  try {
    await body();
    passed.push(name);
  } catch (error) {
    failed.push(`${name}\n      ${error.message.split('\n')[0]}`);
  }
}

await it('a signed out stranger can touch nothing', async () => {
  const stranger = as(null);
  await assertFails(stranger.database.ref('users').get());
  await assertFails(
    stranger.database.ref('users/u1').set({ name: 'Mallory', email: 'm@x.com' }),
  );
  await assertFails(stranger.database.ref('inviteCodes').get());
  await assertFails(stranger.database.ref('groups').get());
});

await it('a user writes their own profile, nobody elses', async () => {
  const alice = await signUp('Purva');
  await assertSucceeds(
    alice.database.ref(`users/${alice.uid}`).update({ name: 'Purva P' }),
  );
  await assertSucceeds(
    alice.database.ref('users/somebody-else').set({ name: 'M', email: 'm@x.com' }),
  ).then(
    () => {
      throw new Error('writing another profile was allowed');
    },
    () => {},
  );
  const stored = await alice.database.ref(`users/${alice.uid}`).get();
  if (stored.val().name !== 'Purva P') throw new Error('the name did not save');
});

await it('a profile needs a name and an email', async () => {
  const alice = await signUp('Purva');
  await assertFails(
    alice.database.ref(`users/${alice.uid}`).set({ email: 'p@x.com' }),
  );
  await assertFails(
    alice.database.ref(`users/${alice.uid}`).update({ name: '' }),
  );
});

await it('a code is claimed once, by the owner of the group that names it', async () => {
  const owner = await signUp('Owner');
  const gid = pushId();
  await seed((database) =>
    database.ref(`groups/${gid}`).set(group('ABC12', owner.uid)),
  );

  await assertSucceeds(owner.database.ref('inviteCodes/ABC12').set(gid));

  // Claimed, so nobody can take it over.
  await assertFails(owner.database.ref('inviteCodes/ABC12').set(pushId()));

  // A code that no group names, and a code that only matches part of a group.
  const stranger = await signUp('Stranger');
  await assertFails(stranger.database.ref('inviteCodes/ZZZ99').set(gid));
  await assertFails(owner.database.ref('inviteCodes/ABC13').set(gid));

  // A group whose name and code disagree cannot be pointed at either.
  await seed((database) =>
    database.ref(`groups/${pushId()}`).set({
      ...group('MISMATCH', owner.uid),
      code: 'ABC12',
    }),
  );
  await assertFails(owner.database.ref('inviteCodes/ABC13').set(gid));
});

await it('a code is claimed for a group id the same length push() makes', async () => {
  // This is the sequence createGroup writes: the group, then the code that
  // points at it, then the owner's own list entry. The id is 21 characters. An
  // earlier cap of 12 passed every test here, because they all used ids like
  // 'g1', and then refused every real group the app created.
  const owner = await signUp('Owner');
  const gid = pushId();
  if (gid.length !== 21) throw new Error(`push id is ${gid.length} characters`);

  await assertSucceeds(
    owner.database.ref(`groups/${gid}`).set({
      ...group('ABC12', owner.uid),
      createdAt: { '.sv': 'timestamp' },
    }),
  );
  await assertSucceeds(owner.database.ref('inviteCodes/ABC12').set(gid));
  await assertSucceeds(
    owner.database.ref(`userGroups/${owner.uid}/${gid}`).set(true),
  );

  // Reading it back proves the values landed whole rather than truncated.
  const claimed = await owner.database.ref('inviteCodes/ABC12').get();
  if (claimed.val() !== gid) throw new Error(`code resolved to ${claimed.val()}`);

  const list = await owner.database.ref(`userGroups/${owner.uid}`).get();
  if (list.val()?.[gid] !== true) throw new Error('the owner list is missing it');
});

await it('anybody signed in can read a code, and see who it points at', async () => {
  const owner = await signUp('Owner');
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', owner.uid));
    await database.ref('inviteCodes/ABC12').set('g1');
  });

  const joiner = await signUp('Joiner');
  const code = await joiner.database.ref('inviteCodes/ABC12').get();
  if (code.val() !== 'g1') throw new Error('the code did not resolve to g1');

  // The group behind it stays unreadable until they are a member.
  await assertFails(joiner.database.ref('groups/g1').get());
});

await it('a group is readable by its members and nobody else', async () => {
  await seed((database) => database.ref('groups/g1').set(group('ABC12', 'owner')));
  await assertSucceeds(as('owner').database.ref('groups/g1').get());

  const stranger = await signUp('Stranger');
  await assertFails(stranger.database.ref('groups/g1').get());
});

await it('joining is adding yourself, and only yourself', async () => {
  await seed((database) => database.ref('groups/g1').set(group('ABC12', 'owner')));

  const joiner = await signUp('Joiner');
  const joinRef = joiner.database.ref(`groups/g1/members/${joiner.uid}`);
  await assertSucceeds(joinRef.set(true));
  await assertSucceeds(joiner.database.ref('groups/g1').get());

  const members = await joiner.database.ref('groups/g1/members').get();
  if (members.val()[joiner.uid] !== true) throw new Error('the join did not land');

  // Re-joining changes nothing, and leaving is allowed.
  await assertSucceeds(joinRef.set(true));
  await assertSucceeds(joinRef.remove());

  // A member cannot bring anybody else in: that is the owner's move.
  const other = await signUp('Other');
  await assertFails(
    joiner.database.ref(`groups/g1/members/${other.uid}`).set(true),
  );
});

await it('a group is created whole, by its first member', async () => {
  const owner = await signUp('Owner');

  await assertFails(
    owner.database.ref('groups/g1').set({
      name: 'Roommates',
      code: 'ABC12',
      ownerId: owner.uid,
    }),
  );

  await assertFails(
    owner.database.ref('groups/g1').set({
      ...group('ABC12', 'somebody-else'),
      members: { 'somebody-else': true },
    }),
  );

  await assertSucceeds(owner.database.ref('groups/g1').set(group('ABC12', owner.uid)));
});

await it('the owner runs the group and cannot hand it to somebody else', async () => {
  await seed((database) => database.ref('groups/g1').set(group('ABC12', 'owner')));

  const owner = as('owner');
  await assertSucceeds(owner.database.ref('groups/g1/name').set('Home Sweet Home'));
  await assertSucceeds(owner.database.ref('groups/g1/kind').set('work'));
  await assertSucceeds(owner.database.ref('groups/g1/activeSession').set('s1'));
  await assertFails(owner.database.ref('groups/g1/ownerId').set('mate'));

  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);

  await assertFails(mate.database.ref('groups/g1/name').set('Their House'));
  await assertFails(mate.database.ref('groups/g1/kind').set('work'));
  await assertFails(mate.database.ref('groups/g1/activeSession').set('s9'));
  await assertFails(mate.database.ref('groups/g1').remove());

  // The whole group cannot be rewritten one field at a time by anybody.
  await assertFails(mate.database.ref('groups/g1').update({ name: 'Theirs' }));
});

await it('a group cannot be deleted by anybody but its owner', async () => {
  await seed((database) => database.ref('groups/g1').set(group('ABC12', 'owner')));
  await assertSucceeds(as('owner').database.ref('groups/g1').remove());
  await assertFails(as(null).database.ref('groups/g1/anything').set(true));
});

await it('a group needs a sane name, code and kind', async () => {
  const owner = await signUp('Owner');
  const uid = owner.uid;

  await assertFails(
    owner.database.ref('groups/g1').set({ ...group('ABC12', uid), kind: 'gym' }),
  );
  await assertFails(
    owner.database.ref('groups/g2').set({ ...group('ABC12', uid), name: 'x'.repeat(41) }),
  );
  await assertFails(
    owner.database.ref('groups/g3').set({ ...group('ABC12', uid), code: 'AB' }),
  );
  await assertFails(
    owner.database.ref('groups/g4').set({ ...group('ABC12', uid), name: '' }),
  );
});

await it('a name a group card shows is readable by anybody signed in', async () => {
  const owner = await signUp('Purva');
  await assertSucceeds(
    owner.database.ref(`publicProfiles/${owner.uid}`).set({ name: 'Purva P' }),
  );

  // The whole node, which is what loading the hub does.
  const names = await as('somebody-else').database.ref('publicProfiles').get();
  if (names.val()[owner.uid].name !== 'Purva P') {
    throw new Error('the name did not come back');
  }

  // Names are readable, the profile behind them is not.
  await assertFails(as('somebody-else').database.ref('users').get());
  await assertFails(as('somebody-else').database.ref(`users/${owner.uid}`).get());

  // And nobody writes a name on somebody else's behalf.
  await assertFails(
    as('somebody-else')
      .database.ref(`publicProfiles/${owner.uid}`)
      .set({ name: 'Mallory' }),
  );
});

await it('a public name needs one, and it is a name', async () => {
  const owner = await signUp('Purva');
  await assertFails(
    owner.database.ref(`publicProfiles/${owner.uid}`).set({ nickname: 'Purva' }),
  );
  await assertFails(
    owner.database.ref(`publicProfiles/${owner.uid}`).set({ name: '' }),
  );
  await assertFails(
    owner.database.ref(`publicProfiles/${owner.uid}`).set({ name: 'x'.repeat(61) }),
  );
});

await it('a brand new account can load an empty hub without being refused', async () => {
  // Exactly what the app does after sign up: read its own group list, then read
  // the names behind the members it found. Both must work with nothing there.
  const fresh = await signUp('Fresh');

  const list = await assertSucceeds(
    fresh.database.ref(`userGroups/${fresh.uid}`).get(),
  );
  if (list.val() != null) throw new Error('a new account should have no groups');

  await assertSucceeds(fresh.database.ref('publicProfiles').get());
});

await it('a members group list is theirs alone to read and write', async () => {
  const owner = await signUp('Owner');
  await seed((database) => database.ref('groups/g1').set(group('ABC12', owner.uid)));

  await assertSucceeds(
    owner.database.ref(`userGroups/${owner.uid}/g1`).set(true),
  );

  const list = await owner.database.ref(`userGroups/${owner.uid}`).get();
  if (list.val().g1 !== true) throw new Error('the list did not save');

  const stranger = await signUp('Stranger');
  await assertFails(stranger.database.ref(`userGroups/${owner.uid}/g1`).set(true));
  await assertFails(stranger.database.ref(`userGroups/${owner.uid}`).get());
  await assertFails(
    owner.database.ref(`userGroups/${owner.uid}/g9`).set(true),
  );
});

await it('a member can drop a group from their own list, and pick it up again', async () => {
  // Undoing a join has to be possible, or a member who joins a group that is
  // then deleted keeps an entry pointing at nothing.
  const owner = await signUp('Owner');
  const gid = pushId();
  await seed((database) =>
    database.ref(`groups/${gid}`).set(group('ABC12', owner.uid)),
  );

  await assertSucceeds(owner.database.ref(`userGroups/${owner.uid}/${gid}`).set(true));
  await assertSucceeds(owner.database.ref(`userGroups/${owner.uid}/${gid}`).remove());

  const list = await owner.database.ref(`userGroups/${owner.uid}`).get();
  if (list.val() != null) throw new Error('the entry is still there');

  // Putting it back is still allowed once the group lists them again.
  await seed((database) =>
    database.ref(`groups/${gid}`).update({ [`members/${owner.uid}`]: true }),
  );
  await assertSucceeds(owner.database.ref(`userGroups/${owner.uid}/${gid}`).set(true));

  // Nobody else can touch it, in either direction.
  const stranger = await signUp('Stranger');
  await assertFails(stranger.database.ref(`userGroups/${owner.uid}/${gid}`).remove());
  await assertFails(
    stranger.database.ref(`userGroups/${stranger.uid}/${gid}`).set(true),
  );
});

await it('a code outliving its group can be cleared away', async () => {
  // joinWithCode undoes its own writes when a code points at a group that has
  // been deleted, and a deleted group leaves its code behind with nothing to
  // redeem it. Otherwise those codes are claimed for good.
  const owner = await signUp('Owner');
  const gid = pushId();
  await assertSucceeds(
    owner.database.ref(`groups/${gid}`).set(group('ABC12', owner.uid)),
  );
  await assertSucceeds(owner.database.ref('inviteCodes/ABC12').set(gid));

  // While the group is there, the code stays put: it cannot be repointed,
  // overwritten, or dropped.
  await assertFails(owner.database.ref('inviteCodes/ABC12').remove());
  await assertFails(owner.database.ref('inviteCodes/ABC12').set(pushId()));

  await seed((database) => database.ref(`groups/${gid}`).remove());
  await assertSucceeds(owner.database.ref('inviteCodes/ABC12').remove());

  const stranger = await signUp('Stranger');
  await assertFails(
    stranger.database.ref('inviteCodes/ZZZ99').set('-NsomeoneElsesGroup'),
  );
});

await it('a session is readable by the group it belongs to', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', 'host'));
    await database.ref('sessions/s1').set(session('g1', 'host'));
  });

  await assertSucceeds(as('host').database.ref('sessions/s1').get());

  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);
  await assertSucceeds(mate.database.ref('sessions/s1').get());

  const stranger = await signUp('Stranger');
  await assertFails(stranger.database.ref('sessions/s1').get());
});

await it('a session is started by a member of that group, for themselves', async () => {
  await seed((database) => database.ref('groups/g1').set(group('ABC12', 'host')));

  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);

  // Somebody outside the group cannot start one at all.
  const stranger = await signUp('Stranger');
  await assertFails(
    stranger.database.ref('sessions/s1').set(session('g1', stranger.uid)),
  );

  // A member can host, but not while putting somebody else in the chair.
  await assertFails(mate.database.ref('sessions/s1').set(session('g1', 'host')));
  await assertSucceeds(
    mate.database.ref('sessions/s2').set(session('g1', mate.uid)),
  );

  await assertSucceeds(
    as('host').database.ref('sessions/s3').set(session('g1', 'host')),
  );
});

await it('a session cannot be repointed at another group', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', 'host'));
    await database.ref('groups/g2').set(group('DEF34', 'mate'));
    await database.ref('sessions/s1').set(session('g1', 'host'));
  });

  const host = as('host');
  await assertFails(host.database.ref('sessions/s1/groupId').set('g2'));
  await assertFails(host.database.ref('sessions/s1').update({ hostId: 'mate' }));
});

await it('a participant votes for a card once, and only for themselves', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', 'host'));
    await database.ref('sessions/s1').set(session('g1', 'host'));
  });

  const host = as('host');
  await assertSucceeds(host.database.ref('sessions/s1/votes/c1/host').set(true));

  const votes = await host.database.ref('sessions/s1/votes/c1').get();
  if (votes.val().host !== true) throw new Error('the vote did not land');

  await assertFails(host.database.ref('sessions/s1/votes/c1/host').set('yes'));

  const stranger = await signUp('Stranger');
  await assertFails(
    stranger.database.ref(`sessions/s1/votes/c1/${stranger.uid}`).set(true),
  );
});

await it('the winner is written once, and only by the host', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', 'host'));
    await database.ref('sessions/s1').set(session('g1', 'host'));
  });

  const host = as('host');
  await assertSucceeds(
    host.database.ref('sessions/s1/winner').set({ cardId: 'c3', type: 'unanimous' }),
  );
  await assertFails(
    host.database.ref('sessions/s1/winner').set({ cardId: 'c7', type: 'closest' }),
  );

  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);
  await assertFails(
    mate.database.ref('sessions/s1/winner').set({ cardId: 'c1', type: 'closest' }),
  );
});

await it('the host ends a session in one update, not by rewriting the session', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set({ ...group('ABC12', 'host'), activeSession: 's1' });
    await database.ref('sessions/s1').set({ ...session('g1', 'host'), status: 'active' });
  });

  // What checkAndDeclareWinner writes: the winner, the status and the group's
  // bookkeeping together, each path checked against its own rule.
  const ending = {
    'sessions/s1/winner': { cardId: 'c3', type: 'unanimous' },
    'sessions/s1/status': 'finished',
    'groups/g1/activeSession': null,
    'groups/g1/sessions/s1': { activity: 'Food', winnerName: 'Taco Bell', date: '14 Nov' },
  };

  // Rewriting the whole session node is refused, because that rule only allows
  // creation. This was the write that left sessions stuck on "active".
  const host = as('host');
  const current = (await host.database.ref('sessions/s1').get()).val();
  await assertFails(
    host.database
      .ref('sessions/s1')
      .set({ ...current, winner: ending['sessions/s1/winner'], status: 'finished' }),
  );

  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);
  await assertFails(mate.database.ref().update(ending));

  await assertSucceeds(host.database.ref().update(ending));
  const pointer = await host.database.ref('groups/g1/activeSession').get();
  if (pointer.val() !== null) throw new Error('the active session was not cleared');

  // A second declaration cannot overwrite the first.
  await assertFails(host.database.ref().update(ending));
});

await it('the host drives the session, and the participants cannot', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', 'host'));
    await database.ref('sessions/s1').set(session('g1', 'host'));
  });

  const host = as('host');

  // The member joins while the lobby is open: Begin locks the participants.
  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);
  await assertSucceeds(
    mate.database.ref(`sessions/s1/participants/${mate.uid}`).set(true),
  );

  await assertSucceeds(host.database.ref('sessions/s1/status').set('active'));
  await assertSucceeds(
    host.database.ref('sessions/s1/cards').set([{ id: 'c1', title: 'Taco Bell' }]),
  );
  await assertSucceeds(host.database.ref('sessions/s1/radius').set(10000));

  await assertFails(mate.database.ref('sessions/s1/status').set('finished'));
  await assertFails(
    mate.database.ref('sessions/s1/cards').set([{ id: 'c2', title: 'Sushi Zen' }]),
  );
  await assertFails(mate.database.ref('sessions/s1/radius').set(1));

  const cards = await host.database.ref('sessions/s1/cards').get();
  if (cards.val()[0].title !== 'Taco Bell') throw new Error('the cards were changed');

  // Nor can the host drop a participant who is not them.
  await assertFails(
    host.database.ref(`sessions/s1/participants/${mate.uid}`).remove(),
  );
});

await it('participants are the members in the room, and nobody is added by accident', async () => {
  await seed(async (database) => {
    await database.ref('groups/g1').set(group('ABC12', 'host'));
    await database.ref('sessions/s1').set(session('g1', 'host'));
  });

  const host = as('host');
  const mate = await signUp('Mate');
  await mate.database.ref(`groups/g1/members/${mate.uid}`).set(true);

  // The host invites, and a member turns up.
  await assertSucceeds(
    host.database.ref(`sessions/s1/participants/${mate.uid}`).set(true),
  );
  await assertSucceeds(
    mate.database.ref(`sessions/s1/participants/${mate.uid}`).set(true),
  );

  // Somebody outside the group cannot put themselves in the room.
  const stranger = await signUp('Stranger');
  await assertFails(
    stranger.database.ref(`sessions/s1/participants/${stranger.uid}`).set(true),
  );

  // And a member cannot bring somebody else along.
  const other = await signUp('Other');
  await assertFails(
    mate.database.ref(`sessions/s1/participants/${other.uid}`).set(true),
  );
});

await testEnv.cleanup();

console.log(`\n${passed.length} passed, ${failed.length} failed`);
for (const name of passed) console.log(`  ok    ${name}`);
for (const name of failed) console.log(`  FAIL  ${name}`);
process.exit(failed.length === 0 ? 0 : 1);