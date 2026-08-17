# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Shelf — a personal, single-user book-cataloging companion app, built with
Flutter (Android + iOS). Notion is the sole source of truth for the `Books`
database Yann already maintains; there is no backend, the app calls the
Notion API (plus Google Books and Open Library for identification) directly
from the client. See `planning/features/NBLM-1.md` for the full scaffold
decision record.

**Property ownership split** (see `docs/Backlog shelf.md` for the full
table): Shelf owns cataloging fields on the `Books` db — `Name`, `Subtitle`,
`Authors`, `ISBN`, `Genres`, `Cover`, `Date published`, `Pages`, `API
categories/subjects`. Reading-progress fields (`Status`, `Current page`,
`Date started`, `Date finished`, `Rating`) belong to the sister Habits app's
Reading module — Shelf displays them read-only and never writes them.

Stack: Flutter/Dart, Riverpod for state, `sqflite` for the offline-first
local cache, `flutter_secure_storage` for the Notion token (scoped to
`Books`/`Authors`/`Genres` only — never the whole workspace),
`mobile_scanner` for barcode capture, `google_mlkit_text_recognition` for
on-device OCR fallback. Deliberately no LLM in the identification pipeline
— see `docs/Backlog shelf.md`'s pipeline section for why.

## Read these before making changes

- **`design/design_handoff_shelf/`** — the finalized, high-fidelity UI spec
  (`README.md` for the written spec + design tokens, `Shelf.dc.html` for an
  executable prototype covering all 13 screens, `screenshots/` for reference
  PNGs, `DESIGN_SYSTEM_habits_reference.md` for the portable-vs-app-specific
  breakdown of the sister app's design system Shelf was built from). Treat
  its measurements/colors/interactions as fixed requirements.
- **`docs/Backlog shelf.md`** — the product spec: property ownership vs.
  Habits, the scan→identify→dedupe→genre-confirm pipeline, the API→Notion
  field mapping table, what's explicitly out of scope for v1.
- **`instructions.md`** — the actual rulebook: planning-doc conventions,
  commit/push policy, versioning, i18n, theming, responsive design, folder
  structure. It's a living document; update it in the same session a new
  rule comes up.
- **`planning/ROADMAP.md`** — index of shipped and planned features, one
  line per milestone (**NBLM-x** ids), linking to that milestone's full
  write-up in `planning/features/NBLM-x.md`. Read the relevant milestone(s)
  before touching code they describe.
- **`planning/CHANGELOG.md`** — index of bugs found and fixed after their
  milestone had already shipped (**NBLB-y** ids), linking to each bug's
  full write-up in `planning/bugs/NBLB-y.md`.
- **`planning/BACKLOG.md`** — ideas not yet scoped into a milestone
  (currently: features explicitly deferred from v1, and an open genre-list
  reconciliation between the backlog spec and the design prototype).

When you finish a real feature, add its `planning/ROADMAP.md` entry as part
of the same task. When you fix a bug outside an in-progress milestone, add
its `planning/CHANGELOG.md` entry the same way. See `instructions.md` for
the exact convention (including commit message format) — commits following
that convention are pre-authorized for this repo; pushes are never
pre-authorized and always need asking first, per `instructions.md`.

## Subagents for scoped work

None yet — this codebase doesn't have a natural split (like a client/server
monorepo would) to scope a subagent to. If a clearly bounded area emerges
later (e.g. the scan/OCR/dedupe pipeline becoming complex enough to warrant
its own context, separate from UI/screens work), propose one to Yann rather
than creating it unprompted.

## Working style

- **Confidence gate**: don't start editing below ~95% confidence in what's
  being asked; ask a targeted question instead of guessing. Once confident,
  stop researching and implement — don't keep exploring "just in case."
- **Analysis budget**: read only the files needed to make the decision at
  hand.
- **Output discipline**: prefer bounded commands over dumping full output;
  read more only when the bounded view doesn't answer the question.

## Applied Learning

Durable, one-line lessons — add a bullet when something fails repeatedly,
Yann needs to explain something again, or a workaround/limitation is
discovered. (These carry over from the sister Habits app — same machine,
same environment.)

- Flutter SDK, Android SDK, and Android Studio are installed under
  `E:\Tools\SDK\` (`flutter`, `android`, `Android Studio`), deliberately
  kept off `C:\`.
- `flutter`/`dart` may not resolve by name in an already-open shell even
  after the user PATH was updated — a registry change doesn't propagate to
  a shell process that was already running. Use the full path
  (`E:\Tools\SDK\flutter\bin\flutter.bat`) rather than assuming the SDK is
  missing; a fresh shell will pick up the PATH update fine.
- `flutter doctor --android-licenses` needs many "y" answers on stdin —
  piping them through PowerShell's object pipeline into the native process
  silently doesn't deliver enough input. Redirect from a real file instead:
  `cmd /c "flutter doctor --android-licenses < yesfile.txt"`.
- No Mac is available in this environment — iOS builds need an external Mac
  or cloud CI (e.g. Codemagic).
- **Never use the Android emulator for testing** — its resource cost is too
  high for this dev machine and it crashes/hangs frequently. Use
  `flutter run -d windows` for manual/UI verification instead. For features
  needing a live Notion connection: `flutter_secure_storage` may already
  have a token persisted from a prior session (check before assuming a
  fresh connect is needed); if a fresh one is genuinely required, either
  read from `notion_token.local` in the repo root if present (Yann has
  authorized this pattern for the sister app; create it for this app only
  once a real, scoped-to-`Books`/`Authors`/`Genres` token exists) or ask
  Yann to be present and set it himself once the app is running.
- Camera-dependent features (`mobile_scanner`, OCR) can't be exercised on
  `flutter run -d windows` — verify those specifically on a real
  Android/iOS device, not the Windows dev target.
