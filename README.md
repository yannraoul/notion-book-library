# Notion Book Library (Shelf)

A personal, single-user book-cataloging companion app built with Flutter
(Android + iOS). **Notion is the sole source of truth** — the `Books`
database Yann already maintains — there is no backend; the app calls the
Notion API, Google Books API, and Open Library API directly from the
client, with a local offline-first cache in front of it.

Shelf scans, identifies, deduplicates, and stores metadata for physical
books: title, subtitle, authors, ISBN, page count, publication date, and
genres — surfaced as a browsable shelf grid with genre filtering. It never
owns or edits reading-progress data (status, current page, dates, rating);
that stays in the sister Habits app's Reading module against the same
`Books` database — Shelf only displays it, read-only.

## Why no backend

Same reasoning as the sister Habits app: the usual reason to keep an API
token off a mobile client is that the app gets distributed to people who
could extract it. This app only ever runs on Yann's own device, so that
risk doesn't apply. The Notion integration token is still stored in the
platform keychain (`flutter_secure_storage`), not plain prefs, and the
integration is scoped to just `Books`/`Authors`/`Genres` rather than the
whole workspace. Full rationale in
[`planning/features/NBLM-1.md`](planning/features/NBLM-1.md).

## Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter/Dart, targeting Android + iOS (Windows also scaffolded, dev-only) |
| State management | Riverpod (`flutter_riverpod`) |
| Remote data | Notion API (client), Google Books API + Open Library API for book identification — all called directly over HTTPS (`http`), no backend |
| Local cache | `sqflite` (+ `sqflite_common_ffi` for the Windows dev target), offline-first cache for scan-then-sync |
| Secure storage | `flutter_secure_storage` — Notion integration token |
| Scanning | `mobile_scanner` (barcode/ISBN), `google_mlkit_text_recognition` (on-device OCR fallback — no LLM in the pipeline, deliberately) |
| Dates/i18n | `intl`, Flutter's ARB tooling (`flutter_localizations`, `l10n.yaml`) — French and English, no hardcoded strings |

## Concepts

- **Book** — the Shelf-owned cataloging fields on Notion's `Books` db:
  title, subtitle, authors (relation), ISBN, genres (relation), cover,
  publication date, page count, plus a raw `API categories/subjects` string
  kept for reference only. Reading-progress fields on the same row (status,
  current page, dates, rating) are owned and written by Habits — Shelf
  reads them for display but never writes them.
- **Identification pipeline** (see
  [`docs/Backlog shelf.md`](docs/Backlog%20shelf.md) for full detail):
  barcode scan → ISBN → Google Books lookup (primary) → Open Library
  fallback. No barcode or a bad cover photo → on-device OCR extracts
  title/author text → fed as a search query to the same two APIs. Both
  fail → manual entry form.
- **Dedupe** — before writing a new book, match against the existing
  `Books` db by ISBN first, then fuzzy title+author. Surfaced as a
  confirm/merge/cancel dialog, never a silent skip or silent duplicate.
- **Genre resolution** — API category/subject data is noisy, so it's never
  auto-written to the `Genres` relation. It's shown as a suggestion,
  cross-checked against existing `Genres` db values, and the user confirms
  or picks manually before anything is written.

## Screens

Shelf grid (All/By genre/Recent tabs), empty/first-run state, scan flow
(barcode/cover-photo toggle), queue review, OCR ranked-candidate list, OCR
manual search, dedupe dialog, genre confirm, manual entry form, book detail
(editable metadata + read-only reading-status card), a 3-screen onboarding
flow, and Settings. The finalized visual spec for all of these lives in
[`design/design_handoff_shelf/`](design/design_handoff_shelf/) — treat its
measurements, colors, and interactions as fixed requirements when touching
UI code.

## Theming

Token-driven (OKLCH values for background/surface/text/muted/border/track),
with light and dark modes and four selectable accent/secondary color themes
shared with the sister app (terracotta — default, vert & rouge, ambre &
ardoise, sarcelle & rouille). Unlike Habits, Shelf has no accent=good/
secondary=bad polarity — instead, book genres get their own fixed-hue cover
colors (`genreColor()` in `lib/theme/color_tokens.dart`), independent of
theme/light-dark mode. Lives in `lib/theme/`, not hardcoded per-widget. See
"Theming" in [`instructions.md`](instructions.md) for the exact rules.

## Project structure

```
lib/
  models/        # Book, Author, Genre, scan-queue item, OCR candidate
  services/      # notion_api.dart, notion_token_storage.dart,
                 # google_books_api.dart, open_library_api.dart,
                 # barcode/OCR scan services, dedupe logic
  repositories/  # mediate between local sqflite cache and Notion; own the offline queue
  database/      # sqflite schema + local stores
  providers/     # Riverpod providers
  screens/       # one per design screen
  widgets/       # shared UI (shelf grid tile, genre chip, confidence pill, ...)
  theme/         # OKLCH color tokens, typography scale, spacing constants
  l10n/          # ARB source strings (app_en.arb / app_fr.arb) + generated AppLocalizations
```

`models/` stays decoupled from Notion's schema — `services/`/`repositories/`
translate to and from Notion's property shape, so the rest of the app never
depends on it directly.

Repo root also holds:

- **`planning/`** — the living project log. `ROADMAP.md` indexes shipped
  milestones (**NBLM-x**, full write-up per milestone in `features/`),
  `CHANGELOG.md` indexes bugs found after their milestone shipped
  (**NBLB-y**, write-ups in `bugs/`), `BACKLOG.md` holds ideas not yet
  scoped into work.
- **`design/`** — the finalized design handoff (read-only reference).
- **`docs/`** — the product/pipeline spec (`Backlog shelf.md`).
- **`instructions.md`** — the contributor rulebook: planning-doc
  conventions, commit/push policy, versioning, i18n, theming, responsive
  design, folder structure.
- **`codemagic.yaml`** — CI config for unsigned iOS builds (no Mac is
  available locally; sideload via the unsigned IPA artifact).

## Getting started

```
flutter pub get
flutter run -d windows   # fastest inner loop for UI work — no Android emulator (see below)
```

Notes specific to this repo's dev environment (same machine as the sister
Habits app):

- Flutter/Android SDKs are installed under `E:\Tools\SDK\`, not `C:\`.
- **Never use the Android emulator** for manual testing — it's too heavy
  for this dev machine and prone to hanging. Use `flutter run -d windows`
  for UI work; camera-dependent features (barcode scan, OCR) need a real
  Android/iOS device instead, since the Windows target has no camera pipeline.
- iOS builds need an external Mac or Codemagic (see `codemagic.yaml`) — no
  Mac is available locally.
- A Notion integration token, scoped to `Books`/`Authors`/`Genres`, is
  required for real data — see `notion_token.local` convention in
  `CLAUDE.md`'s Applied Learning section.

## Status

Pre-alpha — project scaffolding only so far. See
[`planning/ROADMAP.md`](planning/ROADMAP.md) for shipped milestones and
[`planning/BACKLOG.md`](planning/BACKLOG.md) for what's deliberately
deferred from v1.
