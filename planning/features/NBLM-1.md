# NBLM-1 — Project scaffolding

Stack: Flutter (Dart), targeting Android + iOS — no web/desktop targets
shipped (Windows is scaffolded too, but only as a local dev inner-loop, same
reasoning as the sister Habits app). No backend: the app calls the Notion
API, Google Books API, and Open Library API directly over HTTPS from the
client. Full pipeline/property-ownership spec lives in
`docs/Backlog shelf.md`.

**Why no backend is fine here:** same rationale as the sister Habits app —
this only ever runs on Yann's own device, so there's no one else to leak a
client-embedded token to. The Notion token is stored via
`flutter_secure_storage` (Keychain/Keystore), not plain prefs, and the
integration should be scoped to just `Books`/`Authors`/`Genres` — Shelf never
touches reading-progress data (`Status`, `Current page`, dates, `Rating`),
that stays owned by Habits' Reading module on the same `Books` db.

**Dev environment** (same machine as the sister app): Flutter SDK and
Android SDK installed under `E:\Tools\SDK\` rather than `C:\`. No Mac is
available; iOS builds need an external Mac or Codemagic CI
(`codemagic.yaml`, unsigned-build workflow, ported from the sister app
unchanged). Day-to-day dev/testing targets `flutter run -d windows` — no
Android emulator use, same reasoning as the sister app's own Applied
Learning notes (resource cost, frequent hangs on this machine).

**Scope note:** this milestone deliberately bundles what the sister Habits
app did across *two* separate milestones (its own NHTM-1 project
scaffolding, then NHTM-2 localization foundation) into one. This is a
from-reference scaffold pass — replicating an already-proven setup — not
organic incremental development, so there's no reason to artificially split
scaffolding from wiring up l10n.

**Dependencies** added beyond the `flutter create` default: `flutter_riverpod`
(state management), `http` (Notion + Google Books API calls), `flutter_secure_storage`
(token storage), `sqflite` + `sqflite_common_ffi` + `path` (offline-first
local cache, lower write-frequency criticality than Habits but kept for
scan-then-sync-while-offline and pattern consistency), `mobile_scanner`
(barcode/ISBN capture), `google_mlkit_text_recognition` (on-device OCR
fallback when no barcode is found — chosen specifically to avoid LLM key
usage, per `docs/Backlog shelf.md`'s "no LLM, deliberately" note), `intl`
(date formatting), `flutter_localizations` + `generate: true` (ARB-based
l10n, same mechanics as the sister app).

Native setup needed for the scan plugins: Android
`CAMERA` permission in `AndroidManifest.xml`, iOS `NSCameraUsageDescription`
in `Info.plist`.

`lib/` layout: `models/`, `services/` (`notion_api.dart`,
`notion_token_storage.dart`, `google_books_api.dart`, `open_library_api.dart`,
barcode/OCR scan services, dedupe logic), `repositories/`, `database/`,
`providers/`, `screens/`, `widgets/`, `theme/`, `l10n/` — see
`instructions.md`'s "Folder structure" section.

**Theme/l10n foundation** ported from the sister app where portable
(`oklch.dart` verbatim, `spacing.dart` verbatim — the design doc's own
token table uses the same numbers), adapted where Shelf's domain differs
(`color_tokens.dart` drops the accent=good/secondary=bad semantic Shelf
doesn't have and adds a `genreColor()` fixed-hue map instead;
`typography.dart` keeps only the domain-neutral named styles, dropping the
Habits-only ring/stepper ones). `l10n.yaml` + `lib/l10n/app_en.arb` +
`lib/l10n/app_fr.arb` seeded from the copy already written into
`design/design_handoff_shelf/Shelf.dc.html`'s `STRINGS` table. French
default (matching the sister app and the same end user) — flip in
`main.dart`'s `locale:` if that turns out to be wrong for this app
specifically.

- IN: `flutter create` scaffold (`--platforms=android,ios,windows`, org
  `com.yannraoul`, project `notion_book_library`); `pubspec.yaml`
  dependencies added; native camera-permission setup for the scan plugins;
  l10n foundation (`l10n.yaml`, both ARB files, delegates wired into
  `main.dart`); theme foundation (`lib/theme/*.dart`); `instructions.md` +
  `planning/` docs set up; version baselined to `0.0.1+1`.
- OUT: any actual screen/widget code beyond the stock `flutter create`
  counter starter (`lib/main.dart` only gained the l10n delegate wiring and
  the iOS font override, nothing else) — no Notion API integration, no
  local database schema, no real screens from the 13-screen design.
- Done: `flutter pub get` resolves cleanly; `flutter analyze` comes back
  clean.
- Open decisions: state management is **Riverpod**, local DB is **sqflite**
  — both carried over unchanged from the sister app rather than
  re-evaluated, since the same tradeoffs apply (offline-first, small
  relational model, background sync). Scan pipeline is **mobile_scanner +
  google_mlkit_text_recognition**, chosen in `docs/Backlog shelf.md` over an
  LLM-vision approach specifically to avoid overlapping Art Explorer's key
  usage — not revisited here. The genre list used in `color_tokens.dart`'s
  `genreHues` map is the design prototype's 8-genre set, not the backlog
  doc's 7-genre Notion list — see `planning/BACKLOG.md`'s reconciliation
  item, unresolved as of this milestone. French-default locale is an
  assumption (matching the sister app), not a confirmed product decision.
