# LGTM: Frontend Design Spec

You cannot see images, so this file is the single source of truth for how the app looks. Build exactly what is described. All colours, sizes and positions were measured from the original mockups and are close approximations. Where a value says "approx", match it as closely as you can.

App: **LGTM**, a group decision app. Tagline: "Group Decisions, Sorted." Users sign in, join a group, pick a category, swipe on options together, and the app shows a group match or the closest match.

Design name: **Artisanal**. Warm cream paper, deep crimson and forest green accents, editorial serif headings, soft rounded cards with thin rose borders.

---

## 0. Global rules

### Viewport
- Mobile first. Design width is **390px**. On desktop, centre a 390px wide column (max-width 390px, margin auto, full height) and leave the outside area the same cream.
- All screens are vertical mobile layouts. Do not build desktop layouts.

### Fonts (load from Google Fonts)
- **Serif (headings, logo, titles, some buttons):** `Vollkorn`, weights 500, 600, 700, plus italic 700. Fallback: `Georgia, serif`.
- **Sans (body, labels, chips, nav):** `Plus Jakarta Sans`, weights 400, 500, 600, 700. Fallback: `system-ui, sans-serif`.
- Rule of thumb: anything that is a title, card name, logo or the main CTA on setup screens is serif. Anything that is small supporting text, chips, nav labels, status text is sans.

### Colour tokens (approx)
```css
:root {
  --bg: #FDF9F4;            /* main cream background */
  --bg-paper: #ECE9E4;      /* greyer paper background, used on the Swipe screen body */
  --surface: #F0EDE8;       /* greige fill for secondary buttons, rows, chips */
  --surface-2: #F5F1EC;     /* slightly lighter greige for list rows */
  --card: #FEFBF8;          /* card fill, near white cream */
  --primary: #A33A40;       /* crimson, main brand colour */
  --primary-shadow: #7C2A2F;/* darker crimson for hard shadows */
  --reject: #B3262E;        /* red X icon */
  --rose-border: #E6C5C5;   /* thin pinkish border on cards */
  --green: #4D6054;         /* deep sage/forest green */
  --mint: #CFE8D6;          /* mint fill (invite pill, icon tiles) */
  --mint-border: #A9CDB5;
  --ink: #1C1B1A;           /* near black headings */
  --ink-muted: #5C4A4A;     /* brownish grey body text */
  --ink-soft: #7A6E6E;      /* inactive nav icons, placeholders */
  --border-mauve: #8B6B70;  /* outline on login buttons and share button */
  --header-border: #E8E1DA; /* 1px line under top bars */
  --star: #F2C14E;          /* star yellow on match card */
  --sage-deco: #9AA89C;     /* decorative circles */
}
```

### Shape language
- Cards: radius 20px to 40px, 1px `--rose-border`, fill `--card`.
- Primary CTAs: pill (fully rounded) on most screens, 8px radius on Session Setup and Login.
- Chips and badges: fully rounded pills.
- Hard offset shadows (no blur) are used on the Match screen buttons and card. Soft blurred shadows are used on the Swipe action buttons and some CTAs.

### Top app bar (shared pattern)
- Height 64px, background `--bg`, 1px bottom border `--header-border`.
- Side padding 24px. Icons 24px.
- The logo "LGTM" is Vollkorn italic 700. Its colour and size change per screen (see each screen).

### Bottom navigation (ONE common component, identical on every screen that shows it)
Build this once as a shared `BottomNav` component and reuse it. Do not restyle it per screen.

- Screens that show it: Group Hub, Active Swipe, No Consensus Fallback. Login, Create or Join Group, Session Setup and Match have no bottom nav.
- Container: full width of the 390px column, fixed to the bottom, background `--bg` (cream), no visible border, optional very soft top shadow `0 -2px 8px rgba(0,0,0,0.04)`. Height about 88px plus `env(safe-area-inset-bottom)`. Padding top about 14px.
- Four equal-width columns in this order: **Groups**, **Swipe**, **Matches**, **Profile**, with 16px padding on each side of the row.
- Each item is a vertical stack, centred: icon on top, 8px gap, label below.
- Icons are all **filled (solid)** style, about 26px:
  - Groups = two people (one in front, one behind).
  - Swipe = single tilted playing card (rotated about 15 degrees clockwise, with a small notch or dot at the top left corner).
  - Matches = solid five point star.
  - Profile = solid single person (circle head and rounded shoulders).
- **Inactive item:** icon and label colour `--ink-soft` (#7A6E6E, a muted grey brown). Label Plus Jakarta Sans 500, 13px.
- **Active item:** icon and label colour `--primary` (#A33A40, crimson). Label Plus Jakarta Sans 700, 15px (noticeably bolder and slightly larger than the inactive labels). No pill, no background, no underline. Only the colour and label weight change.
- Active tab by route: Group Hub = Groups, Active Swipe = Swipe, No Consensus Fallback = Matches, Profile page = Profile.
- Tapping an item navigates to that tab's route.

### Floating blobs (decorative background shapes, DO implement)
Several screens have soft organic blobs floating in the background. In the mockup export they appear as flat rectangles, but they are meant to be blobs, so build them as organic shapes occupying those same areas.

**Shared blob style**
- Element: `position: absolute`, `z-index: 0`, `pointer-events: none`, placed behind all content (content gets `position: relative; z-index: 1`). The screen container needs `overflow: hidden` so blobs can bleed off the edges.
- Fill: warm greige `#EFECE8` (token `--blob`), opacity 0.9. Optional very soft blur: `filter: blur(1px)`.
- Shape: organic border radius, e.g. `border-radius: 62% 38% 55% 45% / 48% 58% 42% 52%`. Use a slightly different radius per blob so they don't look identical.
- Float animation: slow and subtle, 9 to 14s, `ease-in-out`, `infinite alternate`, translating about 10 to 16px on x and y and rotating about 3 to 6 degrees. Give each blob a different duration and a negative `animation-delay` so they drift out of sync. Wrap in `@media (prefers-reduced-motion: reduce)` to disable the animation.

**Per screen** (coordinates are from the top-left of the 390px screen; the visible area should match these extents)

| Screen | Blob | Visible area | Notes |
|---|---|---|---|
| Login | Greige | x 0 to 100, y 0 to 100 | Bleeds off the top-left corner. Use about 130x130 at top -30px, left -30px |
| Create or Join Group | Greige, large | full width, y 64 to 390 | Sits behind the title and the top of card 1. Use about 470x340 at left -40px, top 64px. Its soft bottom edge ends near y=390 |
| Group Hub | Greige, large | full width, y 64 to 390 | Same as Create Group. Sits behind "My Groups" and the top of the Roommates card |
| Session Setup | Greige, small | x 0 to 100, y 64 to 100 | Bleeds off the left edge. Use about 130x55 at left -30px, top 56px |
| The Match Screen | Greige | x 0 to 100, y 0 to 100 | Same as Login. Stays behind the title |
| No Consensus | Greige, small | x 0 to 100, y 64 to 100 | Same as Session Setup |
| No Consensus (extra) | Dark green `--green`, small | x 0 to 6, y 215 to 278 | A green blob peeking in from the left edge, aligned with the first ranked row. Use about 60x64 at left -54px, top 215px, sits behind the row |

The Swipe screen has no blobs. The Match screen circles in section 6 are part of the same decorative family, so give them the same float animation (smaller travel, about 6 to 10px).

### Images
You cannot see images, so use placeholders until real files are provided. Put real photos in `/public/assets/` using the names given per screen. Until then, use a CSS gradient or solid fallback colour as noted so layout is correct.

---

## 1. Login screen

Plain cream screen, no header, no bottom nav.

- Background: `--bg`.
- **Wordmark** "LGTM": Vollkorn italic 700, about 46px, colour `--green` (#4D6054), left aligned at x=16, top about 255px from the top of the screen.
- **Headline** "Group Decisions, Sorted.": Vollkorn 700, 28px, line-height about 34px, colour `--ink`, left aligned at x=16, about 20px below the wordmark. The text container is narrow (about 150px wide) so it wraps onto exactly three lines: "Group" / "Decisions," / "Sorted.".
- Large empty space between the headline and the buttons.
- **Two stacked buttons** pinned to the bottom, 16px side margins (358px wide each), 56px tall, 12px gap, bottom margin about 48px:
  - Fill `--surface` (#F0EDE9), 2px border `--border-mauve`, radius 8px, tiny shadow `0 2px 0 rgba(0,0,0,0.08)`.
  - Content centred: 16px icon, 8px gap, label in Plus Jakarta Sans 500, 14px, `--ink`.
  - Button 1: bold black "G" Google icon + "Continue with Google".
  - Button 2: black Apple logo icon + "Continue with Apple". (The mockup shows a broken glyph here, use the real Apple logo SVG.)

---

## 2. Group Hub ("My Groups")

- **Top bar:** left hamburger icon (3 lines) in `--ink-muted`; centre "LGTM" Vollkorn italic 700, about 30px, `--primary`; right 40px circular avatar (user photo, dark moody portrait, `/assets/avatar-user.png`, fallback dark grey circle).
- **Page title** "My Groups": Vollkorn 700, 28px, `--ink`, left x=22, about 32px below the bar.
- **Group card 1, "Roommates"**: x=22, width 356, about 493px tall, top about 116px below the title bar bottom (y=180 on screen), radius 40px, 1px `--rose-border`, fill `--card`, padding 24px.
  - Row: dark green (`--green`) filled home icon 20px, 12px gap, "Roommates" Vollkorn 700 22px `--ink`. Far right: vertical kebab (3 dots) 18px `--ink`.
  - 24px gap, then label "ACTIVE MEMBERS": Plus Jakarta Sans 600, 12px, uppercase, letter-spacing 1px, colour `--ink-muted`.
  - Avatar stack below: 4 circles, 38px each, overlapping by about 6px, each with a 2px `--card` ring. Photos are dark moody portraits (`/assets/avatar-1..4.png`, fallback dark grey/teal/purple circles).
  - 1px divider `#DDD6CF` full width inside padding, 24px above and below.
  - Label "PAST WINNERS": same style as ACTIVE MEMBERS.
  - Three rows, each 308px wide, 48px tall, radius 24px (pill), fill `--surface-2`, 1px border `#E8CFCB`, vertical gap about 30px between row tops (78px pitch). Each row: left 36px circle (fill `--mint`) holding a 20px `--green` icon, 12px gap, name in Plus Jakarta Sans 500, 16px, `--ink`.
    - Row 1: "Taco Bell" (taco/fork icon). Row 2: "Sushi Zen" (sushi icon). Row 3: "Burger King" (burger icon).
- **Group card 2, "Hackathon Squad"**: x=22, width 356, height 96px, 24px below card 1, radius 48px, 1px `--rose-border`, fill white `#FFFFFF`. Left: 48px circle fill `#E8E4DE` with a terminal icon (rectangle with ">_") in `--green`. Title "Hackathon Squad" Vollkorn 700 22px `--ink`. Right: chevron ">" 20px `--ink`. 16px horizontal padding.
- **CTA** "Start New Session (Dinner)": x=22, width 356, height 60px, 36px below card 2, radius 30px, fill `--primary`, soft shadow `0 6px 14px rgba(163,58,64,0.3)`. Content centred: white filled circle-with-plus icon 20px, 8px gap, label Vollkorn 600 (serif), 17px, white.
- **Bottom nav:** the common `BottomNav` from section 0, with **Groups** active.

---

## 3. Create or Join Group

- **Top bar:** left back arrow (←) 24px `--primary`; centre "LGTM" Vollkorn italic 700, larger here, about 38px, `--primary`. 1px bottom border.
- **Title** "Create a Group": Vollkorn 700, 28px, `--ink`, centred, about 80px below the top bar.
- **Subtitle** "Start a new decision session or join an existing one.": Plus Jakarta Sans 400, 16px, line-height 24px, `--ink-muted`, centred, wraps to two lines, max width about 350px, 12px below title.
- **Card 1, "Share Invite Link"**: x=16, width 358, about 217px tall, 32px below subtitle, radius 20px, 1px `--rose-border`, fill `--card`, padding 24px.
  - Header row: share-nodes icon 24px `--primary`, 12px gap, "Share Invite Link" Vollkorn 700 22px `--ink`.
  - Body: "Send this link to your squad to get them in instantly." 16px/24px `--ink-muted`, 2 lines, 12px below header.
  - **Link pill**: 308px wide, 53px tall, radius 27px (full pill), fill `--mint`, 1px `--mint-border`, 16px left padding. Text "lgtm.app/invite/vYzA1" Plus Jakarta Sans 500, 14px, `--ink`. Right side: copy icon (two overlapping squares) 22px `--ink`, 16px from the right edge. Clicking copies the text.
- **Card 2, "Enter Group Code"**: same card style, 24px below card 1, about 215px tall.
  - Header row: "enter" icon (arrow into bracket) 24px `--primary`, 12px gap, "Enter Group Code" Vollkorn 700 22px `--ink`.
  - Body: "Have a code? Paste it here to join the session." 16px/24px `--ink-muted`, 2 lines.
  - **Row** with input and button, 12px gap:
    - Input: 236px wide, 50px tall, pill radius 25px, fill `--bg`, 1px border slate grey `#5F6B7A`, padding 0 20px, placeholder "Sample: x7ZA1" Plus Jakarta Sans 400 15px `--ink-soft`.
    - "Join" button: 73px wide, 50px tall, pill, fill `--primary`, white Plus Jakarta Sans 600 14px.
- No bottom nav on this screen.

---

## 4. Session Setup

- **Top bar:** left back arrow 24px `--ink-muted`; centre title "Session Setup" Vollkorn 700, 22px, `--ink`; right horizontal "..." (3 dots) 24px `--ink-muted`. 1px bottom border.
- **Label** "Choose Activity Category": Plus Jakarta Sans 400, 18px, `--ink-muted`, centred, about 48px below the bar.
- **Category chips** (centred, wrapping, 22px horizontal gap, 24px vertical gap), each a rounded rectangle with radius 10px, padding 8px 16px, height about 36px, contains 18px icon, 8px gap, label uppercase Plus Jakarta Sans 600 13px letter-spacing 1px:
  - Row 1: **FOOD** (selected) and **MOVIES**. Row 2, centred: **ACTIVITY**.
  - Selected chip (FOOD): fork-and-knife icon, label, then a small check mark "✓" after the label. Fill `#FDF4F1`, 2px border `--primary`, icon, label and check in `--primary`, shadow `3px 3px 0 #EBC9C6`. About 116px wide.
  - Unselected chips (MOVIES with clapperboard icon, ACTIVITY with gamepad icon): fill `--surface`, 1px border `#DDD7D1`, icon and label `--ink-muted`/`--ink`. MOVIES about 132px wide, ACTIVITY about 139px wide.
  - Only one chip can be selected at a time. Default selected is FOOD.
- **Centre ornament** (settings dial), horizontally centred, vertical centre about 533px from the top, built from three concentric circles:
  - Outer: 252px diameter, 2px dotted (or dashed) border colour `#F0C8CC`, no fill.
  - Middle: 190px diameter, 1px solid `#E8DEDA`, no fill.
  - Inner button: 128px diameter, fill `--surface`, 1.5px border `#D9AFAF`, soft shadow `0 4px 10px rgba(0,0,0,0.08)`. Holds a "sliders" (tune) icon, about 56px, colour `--primary`: three horizontal bars with offset knobs.
  - Tapping the inner button opens extra filters (can be a stub).
- **CTA** "Start Swiping →": pinned near the bottom, x=16, width 358, height 54px, radius **8px** (not a pill), fill `--primary`, 32px from bottom. Label "Start Swiping" in Vollkorn 500, 18px, white, followed by a white right arrow icon 20px with an 8px gap. Content centred.
- No bottom nav on this screen.

---

## 5. Active Swipe

The only screen with the greyer paper background.

- **Background:** body area `--bg-paper` (#ECE9E4) with a subtle paper grain texture (use a faint noise overlay at about 4% opacity). Top bar and bottom nav stay `--bg` cream.
- **Top bar:** left hamburger icon 24px `--primary`; centre "LGTM" Vollkorn italic 700, about 26px, colour **`--ink`** (black, not crimson here); right 40px circular avatar (woman with dark hair, `/assets/avatar-user.png`).
- **Status pill** (live session status): centred, about 288px wide, 30px tall, 16px below the top bar, pill radius, fill `#F5F0EB`, 1px border `--rose-border`. Content: 8px filled dot in `--green`, 8px gap, text "Waiting on 1... (3/4 members swiping)" Plus Jakarta Sans 500, 13px, `#4A3F3F`.
- **Swipe card:** x=26, width 356 (centred), height about 572px, 14px below the pill (y about 119 to 691).
  - **Asymmetric radius:** top-left 28px, top-right 28px, bottom-left 28px, **bottom-right 56px**.
  - Full-bleed photo (`/assets/spicy-basil-thai.jpg`): dark moody close-up of a green Thai basil leaf on the left, red chilli bokeh at top, crispy basil chicken at bottom right. Fallback: dark brown gradient `#2a1a14` to `#0d0b0a`.
  - Dark gradient overlay on the bottom 45%: `linear-gradient(to top, rgba(0,0,0,0.9), rgba(0,0,0,0))`.
  - Bottom-left text block, 24px padding:
    - Title "Spicy Basil Thai": Vollkorn 700, 28px, white.
    - On the same row at the far right, a **rating chip** "★ 4.5": pill, about 55x22, fill `rgba(255,255,255,0.25)` with backdrop blur, white 13px Plus Jakarta Sans 500, small white star.
    - 12px below: outlined location-pin icon 16px + "1.2 miles away" Plus Jakarta Sans 300/400, 17px, white.
    - 12px below: three tag chips "Thai", "$$", "Spicy": pill, height 26px, padding 0 14px, fill `rgba(215,208,202,0.85)` (warm grey), text `#2B2523` Plus Jakarta Sans 500 13px, 8px gap.
  - Swiping the card right = yes (check), left = no (X).
- **Action buttons** row, centred, directly under the card (about 20px gap), 24px gap between buttons, buttons slightly overlap the card's lower area vertically is NOT needed:
  - **Reject**: 64px circle, fill `#F9EDEA`, 1.5px border `#E3B7B5`, X icon 28px `--reject`, offset shadow `5px 5px 0 #EBC9C6`.
  - **Accept**: 80px circle, fill `--green` (#4A5D51), white thick check icon about 36px, offset shadow `5px 5px 0 #BDC4BC`.
  - Buttons are vertically centred with each other.
- **Bottom nav:** the common `BottomNav` from section 0, with **Swipe** active (crimson, not green).

---

## 6. The Match Screen (100% agreement)

Celebration screen. Full cream background, no top bar, no bottom nav.

- **Title** "It's a Match!": Vollkorn italic 700, about 44px, `--primary`, centred, about 50px from the top.
- **Subtitle** "100% Agreement": Vollkorn 700, 22px, `--ink`, centred, 12px below the title.
- **Decorative circles** (purely decorative, `position: absolute`, no pointer events):
  - Sage circle, 36px, `--sage-deco`, at right edge near y=101 (centre x about 368).
  - Small circles beside the subtitle: 16px `--sage-deco` at centre (186,120) and a lighter mint 14px circle at about (212,122), partly behind the subtitle text.
  - Bottom: crimson-rose circle 40px colour `#C97B7E` centred about (75,620), cropped by the bottom edge; mint 30px circle at about (100,622); sage 24px circle at about (268,596).
- **Match card**: x=16, width 358, height about 273px, starts about 18px below the subtitle.
  - Outer frame: fill `--bg`, 1px dark border `#3A2F2F`, radius 16px, padding 8px. **Hard shadow** `6px 6px 0 rgba(58,47,47,0.9)` (brown-black, no blur).
  - Inner photo: 340x256, radius 10px, `/assets/spicy-basil-thai-interior.jpg`: dim warm restaurant interior, cocktail with an orchid garnish on the left, a bowl of curry with rice in the foreground, blurred warm lights in the background. Fallback: dark brown gradient.
  - Bottom gradient overlay to black about 50%.
  - Bottom-left text, 16px inset: "Spicy Basil Thai" Vollkorn 700, 26px, white. Under it a row: yellow star icon (`--star`, outlined) 14px, "4.8", dot separator "•", "$$", dot, "0.5 MI". Plus Jakarta Sans 500, 13px, white, 8px gaps.
  - Bottom-right: 38px circle badge, fill `--bg`, 1px `--primary` border, containing a circle-with-check icon in `--primary`, 22px, sitting about 16px from the right and bottom of the photo.
- **Button "Get Directions"**: x=16, width 358, height 64px, 4px below the card plus its shadow (about 16px gap visually), radius 32px (pill), fill `--primary`, **hard shadow** `0 6px 0 --primary-shadow`. Content centred: white outlined "directions" diamond-arrow icon 24px, 8px gap, label "Get Directions" Plus Jakarta Sans 400, 18px, white.
- **Button "Share to Group Chat"**: x=16, width 358, height 64px, 16px below Get Directions, pill, fill `--surface`, 1px border `--border-mauve`, subtle hard shadow `0 3px 0 rgba(139,107,112,0.4)`. Content centred: share-nodes icon 24px `--ink`, 8px gap, label "Share to Group Chat" Plus Jakarta Sans 400, 18px, `--ink`.
- Optional: a small confetti animation on mount. Keep it light.

---

## 7. No Consensus Fallback ("Closest Match!")

- **Top bar:** left chevron "<" 24px `--primary`, then "LGTM" Vollkorn italic 700, 24px, `--primary`, left aligned right after the chevron (not centred). 1px bottom border.
- **Title** "Closest Match!": Vollkorn 700, 28px, `--ink`, centred, about 38px below the bar.
- **Subtitle** "Couldn't reach 100%. Here are the top options based on group votes:": Plus Jakarta Sans 400, 16px/24px, `--ink-muted`, centred, 2 lines, 12px below title.
- **Ranked list**, 3 rows, x=17, width 357, height about 65px each, 13px vertical gap, 32px below the subtitle. Each row: radius 33px (pill-ish), fill `--surface`, 1px border `#DDD3CB`, padding 0 16px, overflow hidden. Contents left to right, vertically centred:
  - Rank numeral in Vollkorn 700, 18px, `--ink`, as Roman-style display: **"I"**, **"2"**, **"3"** (first is a Roman I, the others are plain digits).
  - 12px gap, 40px circular thumbnail (food photo, fallback dark circle), 12px gap.
  - Option name: Plus Jakarta Sans 600, 16px, `--ink`.
  - Far right: **vote badge** pill, height 28px, padding 0 12px, fill `--bg`, 1px border `#E3D8D0`. Format `6/8 VOTED`: the count in Plus Jakarta Sans 700 13px, "VOTED" in 11px uppercase `--ink-soft`, letter-spacing 0.5px.
  - **Progress bar** along the bottom edge of the row, 3px tall, width proportional to votes / 8 of the row width, left aligned, no radius.
- Row data:
  1. "Spicy Basil Thai", badge `6/8 VOTED`, count colour `--green`, bar colour grey-green `#A9AFA9`, bar width 75%. Thumbnail: dark Thai dish.
  2. "Taco Heaven", badge `3/8 VOTED`, count `--green`, bar `#A9AFA9`, width 37.5%. Thumbnail: tacos.
  3. "Burger Joint", badge `2/8 VOTED`, count colour `#C0646A` (rose), bar `#E8B8B5`, width 25%. Whole row at 70% opacity, rank and name in a lighter grey `#8A7F7F`. Thumbnail: burger.
- **CTA** "FINALIZE DECISION": x=16, width 358, height 60px, 40px below the last row, pill, fill `--primary`, soft shadow `0 6px 14px rgba(163,58,64,0.3)`, white Plus Jakarta Sans 700, 18px, uppercase, letter-spacing 0.5px, centred.
- **Bottom nav:** the common `BottomNav` from section 0, with **Matches** active (crimson star and bold label, no pill, no heart icon).

---

## 8. Routing and flow

1. **Login** → Group Hub.
2. **Group Hub** → "Start New Session (Dinner)" → Session Setup. "+" or "Create group" flow → Create or Join Group.
3. **Create or Join Group**: Join with a code → Group Hub.
4. **Session Setup** → "Start Swiping" → Active Swipe.
5. **Active Swipe**: when everyone agrees on an option → Match Screen. When voting ends without full agreement → No Consensus Fallback.
6. **No Consensus Fallback**: "FINALIZE DECISION" → Match Screen for the chosen option.
7. Bottom nav tabs: Groups = Group Hub, Swipe = Active Swipe, Matches = No Consensus Fallback / matches list, Profile = stub page.

Use mock data for everything (groups, members, restaurants, votes). No backend is required for the first build.

---

## 9. Build checklist

- [ ] Fonts loaded: Vollkorn (500, 600, 700, italic 700) and Plus Jakarta Sans (300, 400, 500, 600, 700)
- [ ] CSS variables above defined once and used everywhere, no hard coded duplicates
- [ ] 390px centred column on desktop
- [ ] Logo colour per screen: green (Login), crimson (Hub, Create Group, No Consensus), black (Swipe)
- [ ] Swipe card has the asymmetric bottom-right radius
- [ ] Hard (no blur) shadows only on the Match screen, Swipe action buttons and the selected FOOD chip
- [ ] Floating blobs built per the table in section 0, behind content, with slow drift animation and reduced-motion fallback
- [ ] One shared `BottomNav` component: filled icons, crimson bold active label (15px), grey brown inactive labels (13px), used on Group Hub, Active Swipe and No Consensus only
- [ ] No em dashes or extra copy added to any text, use the exact strings in quotes above
