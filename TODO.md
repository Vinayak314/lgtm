# Remaining Tasks

## Verification
- [ ] Build and launch the Android debug app on an emulator or device.
- [ ] Verify sign up, sign in, profile name update, group creation, and joining a group with an invite code against Firebase.
- [ ] Add a Leave Group action with confirmation and Firebase cleanup for both `groups/{gid}/members/{uid}` and `userGroups/{uid}/{gid}`; define what happens when the group owner leaves.
- [ ] Review and polish the UI based on the current designs, including responsive layouts and clear loading, empty, and error states.
- [ ] Connect the group invite Share action (currently a placeholder) and make hub actions clearly use the intended group and session category.
- [ ] Wire the session setup and session screens to `SessionBloc` and the Firebase session repository so starting a session actually fetches cards and opens the lobby/swipe flow.
- [ ] Configure and document the required TMDB and Yelp API keys (`TMDB_KEY` and `PLACES_KEY`) for local/debug builds without committing secrets.
- [ ] Verify both APIs return usable movie/food cards, the fetched deck is saved to Firebase, and every participant sees the same cards in the same order.
- [ ] Handle missing keys, API errors, and empty/too-small result decks with a clear recovery path instead of creating an unusable session.
- [ ] Walk through a complete session on two devices or emulators: lobby, host-only Begin, shared voting, unanimous match, and Closest Match/no-match.
- [ ] Verify early finish and waiting progress, session history, and reconnect behavior.
- [ ] Verify denied location permission, network loss and recovery, app interruption, and insufficient API results.

## Follow-up
- [ ] Update the README to reflect current session integration status and setup requirements.
- [ ] Add FCM token handling and a trusted Cloud Function for push notifications if the Firebase plan supports it; the in-app active-session banner currently serves as the fallback.
