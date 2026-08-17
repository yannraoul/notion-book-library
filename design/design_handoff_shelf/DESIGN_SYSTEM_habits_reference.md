# Design System — current state

This documents what's actually implemented today, as opposed to
`design_handoff_habit_tracker/`, which is the original hi-fi spec frozen at
handoff time (read-only, not updated as the app evolves). Where the two
diverge, this file wins — it reflects real code in `lib/theme/`,
`lib/widgets/`, `lib/screens/`, `lib/providers/`, `lib/l10n/`, and
`instructions.md`.

Written to double as a reference for sibling apps: sections are split into
what's a general, portable pattern vs. what's specific to this app's habit
domain.

## 1. Color tokens

All color lives in `lib/theme/color_tokens.dart` + `lib/theme/oklch.dart` —
never hardcoded per-widget. Values are authored in **OKLCH** (`oklch.dart`
hand-rolls the OKLab round-trip since Dart/Flutter has no native `oklch()`)
and exposed as a flat `AppColorTokens` value object with 12 fields:

| Token | Role |
|---|---|
| `bg` | screen background |
| `surface` | card/sheet background |
| `text` | primary text |
| `muted` | secondary text, labels, placeholders |
| `border` | 1px hairlines on cards/inputs |
| `track` | ring/progress-bar unfilled track |
| `dark` | neutral "3rd category" token — see §1.3 |
| `alert` | error/destructive text |
| `accent` / `accentSoft` | theme color 1 + its tinted background |
| `secondary` / `secondarySoft` | theme color 2 + its tinted background |

`AppColorTokens.forTheme(AppTheme theme, {Brightness brightness})` is the
single factory. Widgets never construct tokens themselves — they read
`colorTokensProvider` (a Riverpod `Provider` combining the persisted theme +
appearance choices) and pass the resulting `tokens` object down as a
constructor parameter.

### 1.1 Selectable themes

4 accent/secondary pairs, picked in Réglages, swatch-previewed as two small
dots + label:

- **Terracotta** (default) — warm orange accent, olive-green secondary
- **Vert & rouge** — green accent, red secondary
- **Ambre & ardoise** — amber accent, slate-blue secondary
- **Sarcelle & rouille** — teal accent, rust secondary

`accent`/`secondary` stay **fixed** across light/dark — they were confirmed
to read fine on both backgrounds, so brightness only drives the 8 neutral
tokens (`bg`/`surface`/`text`/`muted`/`border`/`track`/`dark`/`alert`).

### 1.2 Light/dark mode

A second, independent axis ("Apparence": Clair/Sombre) from the color
theme. Every neutral token gets a distinct dark value — dark mode is not a
simple invert or opacity trick, each was chosen and reviewed individually.

### 1.3 Semantic-color rule: what accent/secondary/dark *mean*

This is the one color rule worth calling out for any sibling app that
reuses this token set: **accent/secondary aren't just "brand colors," they
carry meaning** — accent = the positive category, secondary = the negative
category, wherever the domain has a good/bad or on/off polarity. A 3rd,
neutral category (this app's "objectif"/goal) always renders in the `dark`
token, regardless of which of the 4 themes is active, specifically so it
stays visually distinct from both polarities. `dark` can't just be a
near-black in dark mode either (too close to `bg`) — it moves to a mid-grey
so it stays the "odd one out" in both directions. If a sibling app has a
similar 3-way (good/bad/neutral, or on/off/pending) semantic, replicate this
"one token always means this regardless of theme" pattern rather than
inventing a 5th color.

## 2. Typography

`lib/theme/typography.dart` — a named scale (`AppTypography.screenTitle`,
`.habitName`, `.sectionLabel`, `.bodyMuted`, `.rowSubtitle`, `.pillLabel`,
`.stepperValue`, `.detailTitle`, `.navLabel`, etc.), each a function taking
a `Color` (never sets its own color — that always comes from the active
token set) and returning a `TextStyle`. No `fontFamily` set at this layer;
that's left to inherit from the app-level `ThemeData`.

Platform font: Flutter's bundled Roboto already matches Android's system
font, so only iOS gets an explicit override (`fontFamily:
Platform.isIOS ? '.SF Pro Text' : null` in `main.dart`) — the design spec
calls for `-apple-system`/system-ui, and this is the Flutter-side
equivalent.

Letter-spacing from the original CSS spec was authored in `em` (relative to
font size); `emLetterSpacing(fontSize, em)` converts that to Flutter's
absolute-pixel `letterSpacing` at each call site rather than hand-computing
pixel values.

## 3. Spacing & shape

`lib/theme/spacing.dart` — a flat constants class, no scale/multiplier
system, just the literal values the design spec's "Espacements" table
calls for:

- Radii: `cardRadius` 18, `settingsCardRadius` 16, `pillRadius` 20,
  `stepperButtonRadius` 9
- Padding: `screenHorizontalPadding` 20, `cardPaddingVertical` 14,
  `cardPaddingHorizontal` 16
- Gaps: `listGap` 10, `cardRowGap` 12, `stepperGap` 8

Deliberately scoped to what's actually used, not padded out with unused
tokens "for completeness."

## 4. Screen layout pattern

No `AppBar` anywhere in the app. Every top-level screen (`Scaffold` with
`backgroundColor: tokens.bg`) builds its own header inline as the first
child of a `SafeArea` → `ListView`/`Column`:

- **Tab roots** (Home, Stats, Badges, Books, Réglages): a screen-title row
  (`AppTypography.screenTitle`) at the top, occasionally with a trailing
  action (Home's circular "+" button — 36×36, `surface` fill, 1px
  `border`, centered icon).
- **Pushed detail/form screens**: either a text "‹ Back" link
  (`l10n.backLabel`, styled in `accent`) above the title (habit detail), or
  a full custom header row with Cancel/Save text buttons (`add_habit_screen.dart`'s
  `_Header`) — never the platform back chevron + `AppBar` combo.

Content is `ListView`/`Column` with explicit `Padding` per section rather
than a single outer padding — this is what lets different sections (rings,
cards, section labels) each carry their own asymmetric spacing without a
one-size-fits-all wrapper.

Pull-to-refresh: a shared `TopBarRefreshIndicator` widget wraps scrollable
content on data-bearing screens (Home, habit detail), tinted with
`tokens.accent`.

### 4.1 Navigation

Bottom nav only (`AppBottomNav`, 5 tabs: Accueil/Stats/Badges/Books/Réglages)
— no drawer, no `TabBar`. It's a hand-rolled `Row` of `Expanded` +
`GestureDetector` text labels (not Flutter's `BottomNavigationBar` widget),
selected tab in `accent`, others in `muted`, top-bordered `surface`
container. Tab switching goes through a plain `StateProvider<int>`
(`selectedTabProvider`) driving an `IndexedStack` in `RootShell` — so all 5
tab screens stay mounted/alive rather than rebuilding on every switch.

Cross-cutting async feedback (mutation errors, sync results, badge
unlocks, permission denials) is centralized in `RootShell` via
`ref.listen` → `ScaffoldMessenger.showSnackBar`, not scattered per-screen —
one place owns "what pops a snackbar."

## 5. Component patterns

Reusable, general-purpose:

- **Card**: `surface` fill + 1px `border` + `cardRadius` (18), used for
  every list-row-as-card (habit rows, settings blocks, book cards).
- **Pill/badge**: `pillRadius` (20, fully rounded), 1px border in the
  semantic color, soft-tinted background, uppercase small bold label —
  `CategoryPill`.
- **Segmented control**: 2 (occasionally more) `GestureDetector` chips in a
  `Row`, selected = `surface` fill + `text`-colored border, unselected =
  transparent + `border`-colored border. Used for language, appearance, and
  (as a `Wrap`) the 4-theme picker — **not** Flutter's `Switch` or
  `SegmentedButton`. `Switch` is reserved for genuine binary on/off state
  (reminder enabled, per-habit active toggle) — the app's UX convention is
  "mutually-exclusive choice among 2+ named options → segmented chip row;
  literal boolean → `Switch`."
- **Stepper**: two square 28×28 bordered buttons (`–`/`+`) flanking a
  tappable numeric value (tapping the value opens `showValueInputDialog`
  for direct entry, not just increment/decrement).
- **Checkbox control**: 38×38 circle, transparent+bordered when unchecked,
  solid-filled with a white check icon when checked — not Material's
  square `Checkbox`.
- **Rings**: `ConcentricRings`/`SingleRingPercent`
  (`widgets/ring_progress.dart`) — hand-painted `CustomPainter` arcs
  starting at 12 o'clock, clockwise, round stroke caps capped just under a
  full turn to avoid a seam at 100%. A "no value yet" state renders as a
  **dashed track with no value arc** (`dashedTrack: true`) rather than an
  empty/zero-progress ring — used for future days and unset objectives.
  Flutter has no dasharray primitive, so dashing is hand-walked
  arc-by-arc.
- **Primary action button**: solid `accent` fill, white bold text,
  `stepperButtonRadius` corners, full-width — used sparingly (e.g.
  Settings' "Connect" button), built as `GestureDetector` + `Container`,
  not Material's `ElevatedButton`.

**Convention**: essentially no Material widgets are used for anything
visual (`Switch` and `TextField`/`CheckboxListTile` are the exceptions,
kept because restyling them wasn't worth it for how rarely they appear).
Everything else is `GestureDetector` + `Container`/`DecoratedBox` built
directly from tokens. This keeps the app's look fully independent of
Material's default theming rather than fighting it per-widget.

## 6. Modals & dialogs — UX decisions

Two deliberate tiers, chosen by how often the control is touched, not by
convenience:

**Tier 1 — hot-path controls get a platform-native look.** Anything tapped
often during real daily use — the stepper's "set value" entry point
(`showValueInputDialog`), the reminder time picker
(`showAppTimePicker`) — renders as genuinely native chrome per platform:
`CupertinoAlertDialog`/a hand-built `CupertinoDatePicker` sheet on iOS,
Material `AlertDialog`/`showTimePicker` elsewhere. The reasoning written
into the code: on iOS, a Material-styled dialog reads as visibly "wrong"
for something used multiple times a day, so it's worth branching on
`defaultTargetPlatform` for these specific two.

**Tier 2 — rare/deliberate actions stay plain Material everywhere,
deliberately not native.** Multi-step confirm flows that happen
occasionally (start/finish/stop a book, log a reading session) use plain
`showDialog`/`AlertDialog`/`showModalBottomSheet` on both platforms. The
code's own rationale: these aren't a hot path, so there's no per-platform
precedent worth matching, and building a from-scratch Cupertino sheet for
something this rare just adds surface area for the kind of bug tier 1 has
already hit once (see below).

**Bottom sheets** (`showModalBottomSheet`) are used specifically as an
*action picker* — a `ListTile` list of mutually exclusive next steps
(book actions: update page / finish / stop), always wrapped in `SafeArea`,
each row popping the sheet before doing anything (`Navigator.pop()` then
fire the action) so the sheet never sits open across an async operation.

**Dialog content conventions**, consistent across the whole app:
- `AlertDialog`/`CupertinoAlertDialog` content is always
  `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: .start)` —
  never a fixed height.
- An inline editable date row is a plain `Text` with `underline`
  decoration + `GestureDetector` → `showDatePicker`, not a custom date
  widget — one recurring small `_DateConfirmDialog`-shaped pattern reused
  across 3+ flows rather than each flow rolling its own.
- Cancel is always the first/leading action, textual, no confirm-styling;
  the confirming action is the last action and — when its outcome can
  change based on dialog state (e.g. "Save" vs. "Done" depending on
  whether a rating actually changed) — **relabels itself** rather than
  always saying "Save"/"OK".
- Multi-step flows (bump book page → confirm log delta) aren't nested
  dialogs opened from a dialog; each step is `await`ed sequentially from a
  single flow function, and **any cancel at any step aborts the whole
  flow** — no partial writes.
- A star-rating input (`StarRatingInput`) held as local dialog state and
  only committed on the dialog's confirm button — not committed
  immediately per-tap. This was a deliberate correction after an earlier
  tap-to-commit-and-close version proved misclick-prone; local-then-commit
  is now the standing pattern for any multi-value picker inside a dialog.

**Known pitfall already hit once (NHTB-9)**, worth keeping as a checklist
item for any new from-scratch Cupertino sheet: when a sheet's own
`Container` background uses a Cupertino dynamic color, that color must be
**resolved against a themed `BuildContext`** (wrap in `CupertinoTheme` +
`Builder`, pass `brightness` explicitly from the app's own setting) — never
read unresolved, or it silently uses its light-mode value regardless of
the device's actual system appearance, while sibling text in the same
sheet resolves dynamically and can end up unreadable (near-white-on-near-white,
in the case that shipped).

## 7. Theming/settings persistence pattern

A single repeated Riverpod shape, used identically for theme, appearance,
and language (and worth reusing verbatim in a sibling app):

1. An enum (`AppTheme`, `AppAppearance`, `AppLanguage`).
2. A `Notifier<TheEnum>` whose `build()` just returns whatever initial
   value it was constructed with (no async loading inside the provider
   itself), and whose setter (`setTheme`/`setAppearance`/`setLanguage`)
   writes the new state **and** immediately persists it via a shared
   `SettingsStorage` service, in that order.
3. A free `readPersisted*` function, called once during app startup
   (`main.dart`, before `runApp`) to read the stored value back and
   **override the provider's factory** with it — so the very first frame
   already reflects the saved choice, no flash-of-default.
4. Anything derived from 2+ of these axes (`colorTokensProvider`, combining
   theme + appearance into the actual `AppColorTokens`) is its own plain
   `Provider`, not folded into either Notifier.

## 8. Internationalization

Real ARB-based i18n (`flutter_localizations` + `intl`), not a
hardcoded-locale placeholder: `lib/l10n/app_en.arb` / `app_fr.arb`, same
keys in both, generated into `AppLocalizations` via `flutter gen-l10n`
(auto-run by `flutter pub get`/`flutter run` — never hand-edit the
generated file). **2 languages today: French (default) and English**,
switchable via the same segmented-chip pattern as the theme picker,
persisted via the pattern in §7.

Every user-facing string goes through `AppLocalizations.of(context)!.key`
in widgets. Non-widget code that needs a string (extensions, model
helpers) can't reach `BuildContext`, so it takes an `AppLocalizations`
instance as an explicit parameter instead (see `HabitScoring.homeSubtitle`)
— rather than, say, a global/static locale lookup.

Domain data that is itself user-facing text (e.g. a habit's frequency)
is modeled as a small structured type (`HabitFrequency`: `daily` /
`timesPerWeek(n)`) that routes through the same ARB lookup at render time,
instead of storing/passing raw display strings around.

## 9. Responsive design

Phone-only (no tablet/desktop layout target), but explicitly **not** built
to the hi-fi mockup's one reference frame (iPhone, 402×874) as a fixed
canvas. Real devices vary in width/height/aspect ratio, so: safe-area
insets everywhere (`SafeArea` at the top of nearly every screen), scrollable
content instead of fixed pixel offsets, and no assumption about system text
scaling being off.

## 10. What's app-specific vs. portable to a sibling app

**Portable as-is:**
- The OKLCH token architecture + `AppColorTokens.forTheme(theme, brightness)`
  factory shape (§1).
- The typography-scale-as-named-functions pattern (§2).
- The settings-persistence shape in §7.
- The tier-1/tier-2 modal-native-vs-plain decision rule (§6) and its
  concrete dialog conventions (cancel-first, relabeling confirm buttons,
  local-then-commit for multi-value pickers, sequential-await multi-step
  flows with all-or-nothing cancellation).
- The no-`AppBar`, inline-custom-header layout convention (§4).
- "GestureDetector + Container over Material widgets, except where it's
  not worth restyling" (§5).

**App-specific, adapt or drop for a sibling app:**
- The exact 4 theme pairs and their names (§1.1) — the *mechanism* (N
  selectable accent/secondary pairs swatch-picked in settings) is generic,
  the specific terracotta/vert-rouge/ambre-ardoise/sarcelle-rouille palette
  is this app's.
- The accent=good/secondary=bad/dark=neutral semantic mapping (§1.3) — only
  applies if the sibling app has an analogous polarity; the *pattern* of
  "pin one token to one meaning regardless of active theme" generalizes,
  the specific mapping doesn't.
- 5-tab bottom nav with these specific tabs (§4.1).
- French-default, French/English-only language set (§8) — the ARB
  machinery generalizes, the specific 2 languages don't.
