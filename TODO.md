# LGTM To-do List

Work is split into two balanced, end-to-end tracks. Each team member owns frontend and backend work for their feature area; agree on model/API contracts before integrating. Check items off as they are completed.

## Team Member 1: Purva (App foundation, identity, and groups)

### Frontend
- [x] Replace the Flutter counter template with the LGTM app shell.
- [x] Add the Material 3 theme, typography, colors, and shared UI components.
- [x] Add named routes, route argument handling, and an unknown-route screen.
- [x] Add shared loading, error, empty, offline, and confirmation states.
- [x] Build Splash and auth-state loading screens.
- [x] Build Login and Sign Up forms with validation, password visibility, and readable errors.
- [x] Build the My Groups hub with group cards, Create, and Join by code actions.
- [x] Build Create Group and Join Group forms.
- [x] Build Group Detail with member list, invite code/share action, session history entry point, and Start Session action.
- [x] Add Profile / Settings UI with display name and logout action.
- [x] Connect foundation, auth, and group screens to app state and loading/error states using mock data first.
- [x] Check responsive layouts, accessibility labels, and keyboard behavior for these screens.
- [x] Add app icon and launcher branding.

### Backend
- [x] Add null-safe user and group models with JSON conversion.
- [x] Add Provider state for auth and groups.
- [x] Configure Firebase and initialize it in the app.
- [x] Implement email/password sign up, login, logout, and auth-state routing.
- [x] Implement group creation, invite-code joining, group listing, and member data in Realtime Database.
- [x] Add and validate Realtime Database security rules for users and groups.
- [ ] Run the app on a device against the live project: sign up, sign in, update a name, create a group, join one with an invite code.

## Team Member 2: Vinayak (Session setup, live play, and results)

### Frontend
- [ ] Build Start Session options for Movie or Food and the relevant genre/radius controls.
- [ ] Add location permission prompts and a manual/default-city fallback.
- [ ] Show an active-session banner on the hub with a Join action.
- [ ] Build the Lobby with participant avatars/list and host-only Begin control.
- [ ] Build the swipe card and deck UI with image, title, details, rating, progress, and Yes/No controls.
- [ ] Add drag, rotation, fling, and button interactions to the swipe card.
- [ ] Build the Waiting screen with live completion progress.
- [ ] Build the Result screen for unanimous and Closest Match outcomes.
- [ ] Add reveal/confetti animation, Directions, and Share actions.
- [ ] Add a freeze state/overlay when a winner is declared.
- [ ] Connect session screens to app state and loading/error states using mock data first.
- [ ] Add session history UI and refine related empty states.
- [ ] Check responsive layouts, accessibility labels, and keyboard behavior for session screens.

### Backend
- [ ] Add null-safe option card, movie, place, and session models with JSON conversion.
- [ ] Add the session BLoC events and states from the development plan.
- [ ] Implement the TMDB client and normalize movie responses.
- [ ] Implement a places API client (Yelp, Foursquare, or Overpass) and normalize place responses.
- [ ] Fetch, filter, and store a consistent deck of up to 15 options per session.
- [ ] Keep API keys out of source control and pass them through build configuration.
- [ ] Implement session creation, lobby participation, Begin, and participant locking.
- [ ] Synchronize votes and finished status through Realtime Database streams.
- [ ] Detect unanimous votes and declare the winner with a race-safe transaction.
- [ ] Calculate Closest Match with rating and deck-order tie-breaks.
- [ ] Handle late joins, dropped participants, reconnects, and insufficient API results.
- [ ] Ship the active-session in-app banner fallback.
- [ ] Add FCM token handling and a trusted Cloud Function if the Firebase plan supports it.
- [ ] Add session history persistence and retrieval.

## Shared (Integration and delivery)

- [ ] Agree on shared model, route, and database contracts before integrating the two tracks.
- [ ] Verify form validation, API parsing, consensus detection, and Closest Match behavior.
- [ ] Walk through the complete flow on two devices/emulators, including no-match and early-finish cases.
- [ ] Verify denied location, network loss/recovery, and app interruption behavior.
- [ ] Confirm the debug app builds and launches on the Android emulator.

