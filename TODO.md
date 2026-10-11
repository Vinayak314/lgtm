# Remaining Tasks

## Verification
- [ ] Build and launch the Android debug app on an emulator or device.
- [ ] Verify sign up, sign in, profile name update, group creation, and joining a group with an invite code against Firebase.
- [x] Add a Leave Group action with confirmation and Firebase cleanup for both `groups/{gid}/members/{uid}` and `userGroups/{uid}/{gid}`; define what happens when the group owner leaves (blocked while other members remain; sole-owner groups are deleted).
- [ ] Review and polish the UI based on the current designs, including responsive layouts and clear loading, empty, and error states.
- [x] Connect the group invite Share action (currently a placeholder) and make hub actions clearly use the intended group and session category.
- [x] Wire the session setup and session screens to `SessionBloc` and the Firebase session repository so starting a session actually fetches cards and opens the lobby/swipe flow.
- [x] Configure and document the TMDB API key (`TMDB_KEY`) for movie sessions; food sessions use local mock places and require no Yelp key.
- [ ] Verify TMDB returns usable movie cards, the five mock food cards are usable, the deck is saved to Firebase, and every participant sees the same cards in the same order.
- [x] Handle missing keys, API errors, and empty/too-small result decks with a clear recovery path instead of creating an unusable session.
- [ ] Walk through a complete session on two devices or emulators: lobby, host-only Begin, shared voting, unanimous match, and Closest Match/no-match.
- [ ] Verify early finish and waiting progress, session history, and reconnect behavior.
- [ ] Verify denied location permission, network loss and recovery, app interruption, and insufficient API results.

## Follow-up
- [x] Update the README to reflect current session integration status and setup requirements.
- [ ] Add FCM token handling and a trusted Cloud Function for push notifications if the Firebase plan supports it; the in-app active-session banner currently serves as the fallback.
