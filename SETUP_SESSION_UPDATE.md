# Setup for the session fixes and live standings

What changed:

- **Sessions now end.** A card everyone swipes Yes on wins straight away. If nobody agrees, the closest match wins once everyone has finished. The host's phone saves the result in one atomic Firebase update, and the group's "active session" link clears with it.
- **Live standings.** Once you finish your own deck, the waiting screen shows every option ranked by Yes votes. It updates live until the host's phone confirms the winner.

**No database rule changes were needed.** The fix works with the `database.rules.json` already in the repo. You still need to make sure those rules are the ones actually deployed (step 1.2).

---

## 1. Firebase console

### 1.1 Confirm which project the app uses (do this first)

The app and the repo's Firebase settings point at different projects:

| Where | Project |
|---|---|
| `lib/firebase_options.dart` (what the app connects to) | `flutter-project-e0c40`, database in `asia-southeast1` |
| `.firebaserc`, README links, `firebase deploy` default | `lgtm-app` |

Rules deployed to `lgtm-app` never reach the app. Pick one project and make the repo agree with it:

- **If `flutter-project-e0c40` is the real project:** run `firebase use --add`, choose `flutter-project-e0c40` and alias it `default`, or edit `.firebaserc` by hand. Then update the console link in the README.
- **If `lgtm-app` is the real project:** run `flutterfire configure --project=lgtm-app` to regenerate `lib/firebase_options.dart`, then download a fresh `google-services.json` from that project.

`android/app/google-services.json` must come from the same project as `lib/firebase_options.dart`.

Every console step below happens in that project.

### 1.2 Make sure the deployed rules are the repo's rules

1. Open **Build -> Realtime Database -> Rules**.
2. Compare what is there with `database.rules.json` in the repo.
3. If they differ, publish the repo version. This includes test-mode rules: `".read": true` / `".write": true`, or a `now < ...` expiry, which locks everyone out once the date passes. Two ways to publish:
   - CLI, from the repo root. Install and sign in once per machine first:
     ```bash
     npm install -g firebase-tools
     firebase login
     firebase deploy --only database --project flutter-project-e0c40
     ```
     Use your project id from 1.1.
   - Console: paste the file's contents into the Rules editor and press **Publish**.

### 1.3 Optional: check the key rule in the Rules Playground

In **Rules -> Rules Playground**, simulate a **set** while authenticated as the session host's UID. Use the id of any session that has no winner yet:

| Location | Expected | Why |
|---|---|---|
| `/sessions/<sid>/winner` with `{"cardId": "c1", "type": "unanimous"}` | Allowed | the host may write the winner once |
| The same, with another member's UID | Denied | only the host ends a session |
| `/sessions/<sid>` with the whole session object | Denied | the old app did this, which is why sessions never ended |

The emulator suite in section 4 checks all of this automatically.

### 1.4 Sessions stuck from before the fix

You don't need to clean anything up. When the **host** opens the group and taps the session button, the app rejoins and declares the winner, provided the votes have already decided one (everyone liked one card, or everyone finished). The group's banner then clears for every member.

On the old build, a member could swipe the whole deck without being marked finished. If nobody agreed on a card, the host reopening that session isn't enough. **That member opens the session once on the new build**, which marks them finished, and then the host's app can declare the closest match. Do this before reaching for the manual fix below.

The only manual case is a session that can never finish, for example because a participant uninstalled before swiping their deck. Clear it from **Realtime Database -> Data**:

1. Open `groups/<gid>`.
2. Delete the `activeSession` field.

That lets the owner start a new session. The old `sessions/<sid>` record can stay; nothing reads it once the group no longer points at it.

### 1.5 Nothing else is needed

- No new indexes, Cloud Functions, Auth providers or billing plan.
- The standings only read `sessions/<sid>`, which group members can already read.

---

## 2. On every device

**Install the new build on every phone in the session, host and members alike.** Each phone marks its own user as finished and draws its own standings. A participant still on an old build can stall a session.

From the repo root, with `android/app/google-services.json` in place (see README, Setup):

```bash
flutter pub get
flutter run --dart-define=TMDB_KEY=your_tmdb_key
```

To install on a phone that isn't plugged into your machine, build an APK and copy it over:

```bash
flutter build apk --debug --dart-define=TMDB_KEY=your_tmdb_key
# -> build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

`TMDB_KEY` is only needed for movie sessions. Food sessions work without it.

**If Google sign-in fails on a build from another machine**, that machine's debug signing key isn't registered:

1. Run `cd android && ./gradlew signingReport` and copy the `SHA1` of the `debug` variant.
2. Add it in **Project settings -> Your apps -> Android app -> SHA certificate fingerprints**.
3. Download `google-services.json` again and rebuild.

---

## 3. Walkthrough with two phones

Sign both phones into different accounts, both members of the same group.

1. **Start.** The owner opens the group and starts a session. The second phone joins the lobby, and the host taps **Begin**.
2. **Unanimous match.** Both phones swipe Yes on the same card. Expected:
   - both phones show "Everyone chose this!" immediately, without finishing the deck
   - the group's active-session banner disappears
   - the owner can start a new session
3. **Closest match.** Start a new session where nobody agrees.
   - The first phone to finish sees **Live Standings**, with "Waiting on 1... (1/2 finished)".
   - The counts move as the other phone keeps swiping.
   - When both are done, both phones show "Closest match", and the card is the top row the standings showed.
4. **Host away.**
   - The host finishes first and force-closes the app by swiping it away from recents. A backgrounded app can stay connected and declare the winner anyway, which would make this step look broken. The member finishes.
   - The member sees "Everyone is done" and "Waiting for the host to confirm the top pick."
   - The host reopens the app and taps the group's session button. Both phones then show the result.
5. **Resume.** Kill the app mid-deck and reopen the session. It resumes on the first card you haven't voted on.
6. **History.** The group's past sessions list the winner.

---

## 4. Developer checks (optional)

App logic. All 13 tests should pass:

```bash
flutter test test/session_bloc_test.dart
```

Database rules against the emulator. All 26 should pass, including "the host ends a session in one update, not by rewriting the session":

```bash
npm install -g firebase-tools          # once; the emulator needs a JDK (21 works)
cd tool/rules && npm install && cd ../..

firebase emulators:start --only database --project lgtm-app   # terminal 1
node tool/rules/rules_test.mjs                                # terminal 2
```

The emulator runs locally, so the project id here doesn't matter. Keep the two terminals separate. `firebase emulators:exec` sets `FIREBASE_DATABASE_EMULATOR_HOST` to `host:port`, which the suite reads as a bare host. If you use `exec`, prefix the command with `env -u FIREBASE_DATABASE_EMULATOR_HOST`.

Five older test files (`a11y`, `auth_flow`, `profile`, `router`, `state`) don't compile against the current code. That predates these changes, so run the session test file directly rather than the whole `flutter test` suite.

---

## Known limits

- **Only the host's phone can end a session**, because the rules only let the host write the winner. Until the host's app is open again, members see the standings and "Waiting for the host to confirm". Removing that wait would need either a Cloud Function or rules that let any participant declare.
- **Standings stay hidden while you are still swiping**, so the tally can't sway your own votes. This is set in the bloc, which only shows the standings in the waiting state.
