# LGTM: Flutter Development Plan

**Pitch:** Tinder for group decisions. Swipe together, match on the one thing everyone actually wants.

**Stack:** Flutter (Dart) · Firebase Auth · Firebase Realtime Database · FCM · TMDB / Yelp (or alternative) · Provider + BLoC

---

## 1. Design decisions (from the "Solutions" section)

| Open question | Decision |
|---|---|
| Group model | **Persistent groups** ("Roommates", "Hackathon Squad") on a "My Groups" hub. No random link per session. Members join a group once via an invite code. |
| Session trigger | Any group member taps **Start Session** (e.g. Dinner, 5 miles). The rest of the group gets a **push notification** to open the app. |
| Deck | Capped deck of **15 real options** from live public APIs (TMDB for movies, Yelp/alternative for food). No mock data in the final build. |
| Voting | **Binary Yes/No swipe.** Unlimited Yes swipes allowed. |
| Consensus | **Dynamic 100% consensus.** The first option that gets a Yes from *every active participant* wins. Threshold = number of people who joined the session, not the group size (5 in group, 3 joined → threshold 3). |
| Reveal | The instant an option crosses the threshold, swiping freezes and the winner takes over every screen with a celebration animation plus **Directions** and **Share** buttons. |
| Fallback | If all 15 cards are used with no unanimous winner, tally votes and show the highest-scoring option as the **"Closest Match"**. |

**Additions recommended by this plan (to make the rules safe):**
- **Lobby phase:** "active participants" are fixed when the host taps **Begin**. The threshold then never changes mid-swipe.
- **Tie-break in fallback:** higher API rating wins; if still tied, the earlier card in the deck.
- **Host fetches the deck once** and stores it in the session, so everyone sees the same 15 cards in the same order.

---

## 2. User loop → screens

| Step | What happens | Screens involved |
|---|---|---|
| 1. The Hub | Open app to "My Groups" | Splash, Login/Sign Up, My Groups |
| 2. The Trigger | Member starts a session; group is pinged | Group Detail, Start Session, Notification / in-app banner |
| 3. The Swipe | Each person swipes 15 cards on their own phone | Lobby, Swipe, Waiting |
| 4. The Reveal | Winner appears for everyone at once | Result (unanimous or Closest Match) |

---

## 3. Features

### Must-have (MVP)
- Email/password auth with form validation
- Create group, join group by code, list "My Groups"
- Group detail: members, invite code, Start Session
- Start Session: category (Movie / Food), radius or genre
- Push notification to group members when a session starts
- Lobby with live participant list; host taps Begin
- Swipe deck of 15 live API cards (drag + rotate, Yes/No buttons as alternative)
- Real-time vote sync across devices
- Dynamic 100% consensus detection and simultaneous freeze
- Winner reveal with celebration animation, Directions and Share
- Fallback "Closest Match"
- Loading, error and empty states

### Should-have
- Waiting screen after finishing your 15 cards
- Session history per group
- Profile/Settings (display name, logout)
- Location permission handling with fallback city
- AdMob banner and post-result interstitial

### Stretch
- Google sign-in
- "Veto" feature
- Group chat or reactions on the result
- Remove-ads in-app purchase
- Dark mode

---

## 4. Screens

| # | Screen | Key widgets and behaviour |
|---|---|---|
| 1 | **Splash** | Checks auth state, routes to Login or Hub |
| 2 | **Login / Sign Up** | `Form` + `GlobalKey<FormState>`, `TextFormField` validators, obscured password, error SnackBar |
| 3 | **My Groups (Hub)** | `ListView.builder` of group cards, FAB "Create", "Join with code" action, banner "Roommates started a session, Join" |
| 4 | **Create / Join Group** | Form with group name, or 6-character code field |
| 5 | **Group Detail** | Member list, invite code + share, **Start Session** button, past results |
| 6 | **Start Session** | Category selector, radius slider (e.g. 5 miles) or genre, location permission request |
| 7 | **Lobby** | Real-time participant avatars, "Join" for members, host-only **Begin** button |
| 8 | **Swipe** | Card stack, progress "7 / 15", Yes/No buttons, freeze overlay on win |
| 9 | **Waiting** | Shown when you finish before others; live "3 of 4 finished" |
| 10 | **Result / Reveal** | Winner card, confetti, Directions (`url_launcher`), Share (`share_plus`); "Closest Match" variant |
| 11 | **History** | Past decisions per group |
| 12 | **Profile / Settings** | Name, logout |
| 13 | **404 screen** | `onUnknownRoute` |

---

## 5. Architecture

```
lib/
├── main.dart
├── app/
│   ├── routes.dart              # named routes, onGenerateRoute, onUnknownRoute
│   └── theme.dart               # Material 3
├── models/
│   ├── app_user.dart
│   ├── group.dart
│   ├── option_card.dart         # abstract base: id, title, imageUrl, subtitle, rating, mapsUrl
│   ├── movie_card.dart          # extends OptionCard
│   ├── place_card.dart          # extends OptionCard
│   └── session.dart
├── services/
│   ├── auth_service.dart
│   ├── group_service.dart
│   ├── session_service.dart     # RTDB streams + transactions
│   ├── movie_api.dart           # TMDB
│   ├── places_api.dart          # Yelp / Foursquare / Overpass
│   ├── location_service.dart    # geolocator
│   └── notification_service.dart# FCM token + handlers
├── providers/                   # Provider + ChangeNotifier
│   ├── auth_provider.dart
│   └── group_provider.dart
├── blocs/session/               # BLoC: the live swipe engine
│   ├── session_bloc.dart
│   ├── session_event.dart
│   └── session_state.dart
├── screens/                     # one folder per screen
└── widgets/                     # swipe_card.dart, member_avatar.dart, winner_overlay.dart ...
```

### State management split
- **Provider + ChangeNotifier:** auth state, group list, current user. Simple app-wide state.
- **BLoC:** live session. Stream-heavy (participants, votes, winner), so events and states map cleanly.

### BLoC design

**Events:** `SessionStarted`, `ParticipantsUpdated`, `SessionBegan`, `CardSwiped(cardId, liked)`, `VotesUpdated`, `WinnerDetected`, `DeckFinished`.

**States:** `SessionLobby`, `SessionSwiping(currentIndex, cards)`, `SessionWaiting`, `SessionWon(card, type)`, `SessionError`.

---

## 6. Data model (Realtime Database)

```
users/{uid}:        { name, email, fcmToken }

groups/{gid}: {
  name, code, ownerId,
  members: { uid: true }
}

sessions/{sid}: {
  groupId, hostId, category, radius, createdAt,
  status: "lobby" | "active" | "finished",
  cards: [ { id, title, image, subtitle, rating, mapsUrl } x 15 ],
  participants: { uid: true },        // frozen at Begin
  votes: { cardId: { uid: true|false } },
  finished: { uid: true },
  winner: { cardId, type: "unanimous" | "closest" }
}

groups/{gid}/activeSession: sid | null    // drives the "Join" banner
```

---

## 7. The engine (core logic)

### 7.1 Session lifecycle
1. **Start:** host picks category and radius. App fetches 15 options from the API, creates `sessions/{sid}` with `status: "lobby"`, sets `groups/{gid}/activeSession`, and triggers the push notification.
2. **Lobby:** members who open the app tap Join, which writes `participants/{uid} = true`.
3. **Begin:** host taps Begin. `status = "active"`. The participant list is now locked and `threshold = participants.length`.
4. **Swipe:** each swipe writes `votes/{cardId}/{uid} = true|false`.
5. **Detect:** every client listens to `votes`. If any card's Yes count equals `threshold`, attempt to declare a winner.
6. **Declare (race-safe):** use a transaction that sets `winner` only if it is currently null.
7. **Reveal:** all clients listen to `winner`. When it appears, swiping freezes and the Result screen opens.
8. **Fallback:** when `finished` count equals `threshold` and there is no winner, tally Yes votes, pick the top card and write `winner` with `type: "closest"`.

### 7.2 Winner detection (sketch)

```dart
String? findUnanimousCard(Map<String, Map<String, bool>> votes, int threshold) {
  for (final entry in votes.entries) {
    final yes = entry.value.values.where((v) => v).length;
    if (yes == threshold) return entry.key;
  }
  return null;
}

Future<void> declareWinner(DatabaseReference sessionRef, String cardId, String type) {
  return sessionRef.child('winner').runTransaction((current) {
    if (current != null) return Transaction.abort(); // someone already won
    return Transaction.success({'cardId': cardId, 'type': type});
  });
}
```

### 7.3 Fallback tally (sketch)

```dart
OptionCard closestMatch(List<OptionCard> cards, Map<String, Map<String, bool>> votes) {
  int yesCount(OptionCard c) =>
      (votes[c.id]?.values.where((v) => v).length) ?? 0;

  return cards.reduce((a, b) {
    final diff = yesCount(a) - yesCount(b);
    if (diff != 0) return diff > 0 ? a : b;
    return a.rating >= b.rating ? a : b;   // tie-break by rating
  });
}
```

### 7.4 Edge cases

| Case | Handling |
|---|---|
| Person closes app mid-session | Host gets "Skip waiting" after a timeout, which removes absent users and lowers the threshold |
| Two phones detect win simultaneously | Transaction guarantees a single winner |
| Only one participant | Allowed; treated as solo mode |
| Late joiner after Begin | Blocked. Shown "Session already started" |
| API returns fewer than 15 results | Use what came back (minimum 5); if fewer, show error and let host retry |
| Location denied | Use a default city or ask for manual entry |
| Network loss | Queue vote locally, retry; show offline banner |

---

## 8. Notifications (the Trigger step)

The doc specifies a push notification to the rest of the group. Sending a push to *other* users needs a trusted server, so a client cannot do it alone.

**Primary approach (matches the doc):**
- Each user's FCM token is saved at `users/{uid}/fcmToken`.
- A **Cloud Function** triggers on new `sessions/{sid}` and sends an FCM message to every group member except the host.
- Requires Firebase **Blaze** plan (pay-as-you-go, with a free quota that a mini project won't exceed; a card is needed to enable it).
- App handles foreground, background and terminated states with `firebase_messaging` plus `flutter_local_notifications`, and deep-links to the Lobby using named routes.

**Free fallback (no billing needed):**
- Members' apps listen to `groups/{gid}/activeSession` in the Realtime Database.
- When it becomes non-null, show an **in-app banner** on the Hub ("Roommates started a session. Join").
- Works only while the app is open, so mention this limitation in your report.

Build the fallback first, then upgrade to FCM in Phase 5.

---

## 9. APIs

| Category | API | Notes |
|---|---|---|
| Movies | **TMDB** (`/discover/movie` or `/movie/popular`) | Free key; images via `image.tmdb.org` |
| Food / places | **Yelp Fusion** (`/businesses/search`) as named in the doc | Free trial tier is limited; if it blocks you, use **Foursquare Places** or **OpenStreetMap Overpass** |

**Normalisation:** each API response is mapped into `OptionCard` subclasses (`MovieCard`, `PlaceCard`) so the swipe UI and engine are category-agnostic.

**Fetch rules:** request more than 15, filter out results with no image, then take the top 15.

**Secrets:** never commit keys. Use `--dart-define=TMDB_KEY=...` or a git-ignored config file.

---

## 10. Security rules (Realtime Database)

Principles:
- Only signed-in users can read or write.
- Only group members can read a group or its sessions.
- A user can write only their own vote (`votes/{cardId}/{their uid}`).
- `winner` can be written once (only if it does not exist).
- Only the host can change `status` and write `cards`.

Write and test these in the Firebase Rules Playground before Phase 5.

---

## 11. Packages

| Purpose | Package |
|---|---|
| Firebase | `firebase_core`, `firebase_auth`, `firebase_database`, `firebase_messaging` |
| State | `provider`, `flutter_bloc`, `equatable` |
| HTTP | `http` |
| Location | `geolocator` |
| Links / share | `url_launcher`, `share_plus` |
| Notifications | `flutter_local_notifications` |
| Animation | `confetti` (or `lottie`) |
| Swipe cards (fallback) | `flutter_card_swiper` |
| Ads | `google_mobile_ads` |
| Icons | `flutter_launcher_icons` |
| Image caching | `cached_network_image` |

---

## 12. Build phases

### Phase 0: Planning and setup
- Finalise Figma screens (link in your brief).
- Set up Flutter, Android Studio, emulator; create project and Git repo.
- Create Firebase project; run `flutterfire configure`.
- Register TMDB and Yelp/Foursquare API keys.
- **Deliverable:** app runs on emulator; Firebase connected.

### Phase 1: Dart foundations and UI shell
- Model classes with null safety, `fromJson`/`toJson`; abstract `OptionCard` with `MovieCard`/`PlaceCard`.
- Material 3 theme, custom font, assets.
- Named routes with `onGenerateRoute` and `onUnknownRoute`.
- Build Splash, Login/Sign Up (validated forms), My Groups, Group Detail, Start Session with **mock data**.
- Drawer or BottomNav, FAB, SnackBars.
- **Swipe card widget** using `GestureDetector`, `Transform.translate` + `Transform.rotate`, and a fling animation.
- **Deliverable:** clickable app with mock data and a working swipe card.

### Phase 2: Auth, groups and APIs 
- Firebase Auth (sign up, login, logout, auth-state routing).
- Provider layer: `AuthProvider`, `GroupProvider`.
- Group create, join by code, list, with real RTDB data.
- Integrate TMDB and the places API with `http` and JSON parsing; handle errors and empty results.
- Location permission and radius search.
- **Deliverable:** real groups and real 15-card decks displayed in the swipe screen (single user).

### Phase 3: Live session engine
- `SessionService`: create session, join lobby, begin, stream votes.
- `SessionBloc` with the events and states in section 5.
- Lobby screen with live participants and host-only Begin.
- Vote writes, consensus detection, transaction-based winner, freeze and simultaneous reveal.
- Waiting screen and fallback Closest Match.
- Handle the edge cases in section 7.4.
- **Deliverable:** two devices swipe and see the same winner at the same time.

### Phase 4: Notifications and polish
- In-app active-session banner (free fallback).
- FCM plus Cloud Function (if using Blaze); deep link to Lobby.
- Confetti or Lottie celebration, Directions and Share buttons.
- Loading skeletons, error and empty states, offline banner.
- Session history and Profile screens.
- **Deliverable:** full loop works end to end with a notification.


---

## 13. Testing checklist

**Unit:** `findUnanimousCard`, `closestMatch`, JSON parsing for both APIs, form validators.

**Bloc tests:** state transitions (lobby → swiping → won / waiting).

**Manual multi-device scenarios:**
- 2 devices, both Yes on the same card → winner appears simultaneously on both
- 3 in group but 2 join → threshold is 2
- Nobody agrees → Closest Match appears after all finish
- One user finishes early → Waiting screen, then reveal
- App killed mid-session → host skip flow
- Location denied → fallback city
- Airplane mode during swipes → recovers on reconnect

## 14. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Yelp free tier limits | Switch to Foursquare or Overpass behind the same `PlacesApi` interface |
| Push needs paid plan | Ship in-app banner first; treat FCM as an upgrade |
| Race conditions on winner | RTDB transaction on `winner` |
| Demo needs 2 devices | Use emulator plus physical phone, or two emulators |
| Scope creep | Freeze MVP list in section 3; stretch goals only after Phase 5 |
| API key leakage | `--dart-define`, `.gitignore` config |
