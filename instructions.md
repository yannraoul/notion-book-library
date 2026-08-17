# Instructions for working on this repo

Living document — when a new rule is discussed and agreed with Yann, add it
here in the same session, not as a follow-up. Don't remove a rule just
because it seems obvious in hindsight; remove it only when Yann explicitly
supersedes it.

## Planning documents: where things get logged

Three files, one job each:

- **`planning/ROADMAP.md`** — index of real, scoped features/scope changes,
  one line per milestone, identifier **NBLM-x** (Notion Book Library
  Milestone), in commit order. Full detail for each milestone lives in its
  own `planning/features/NBLM-x.md` file. Write the `planning/features/NBLM-x.md`
  entry (and its `planning/ROADMAP.md` index line) as part of finishing the
  milestone, not as a follow-up task.
- **`planning/CHANGELOG.md`** — index of bug fixes discovered *after* the
  milestone that introduced them has already shipped, identifier **NBLB-y**
  (Notion Book Library Bug), one line per bug. Full detail lives in its own
  `planning/bugs/NBLB-y.md` file. A bug found and fixed while a milestone is
  still actively being built stays inside that milestone's own
  `planning/features/NBLM-x.md` entry instead — NBLB is only for things that
  slipped through and surfaced later.
- **`planning/BACKLOG.md`** — ideas worth keeping that haven't been scoped
  into actual work yet. Once one is picked up, it graduates to
  `planning/ROADMAP.md` with a real NBLM-x id and is removed from here.

Commit message pattern: `feat: NBLM-x <milestone name>` for milestone work,
`fix: NBLB-y <what was fixed>` for changelog work, `fix: NBLM-x <what was
fixed>` for a same-session fix to a milestone that's still fresh (not yet
promoted to its own NBLB entry — see the CHANGELOG.md rule above), `chore:
<what changed>` for anything else (docs restructuring, tooling, cleanup).

**The subject line is the entire message.** No body, no bullet list, no
rationale paragraph, and no `Co-Authored-By` trailer — save all of that for
conversation or a PR description. `feat: NBLM-3 Shelf grid screen` is a
complete, correct commit message on its own.

Several commits made against the same milestone while testing/fixing
mid-development are fine, and normally left for Yann to squash himself —
don't `git commit --amend` or rebase unprompted. But **on explicit request**,
squash a milestone's `feat:`/`fix:` sequence from the same session down to
one `feat: NBLM-x` commit for that milestone.

## Commits and pushes

- **Commits are pre-authorized** for this repo specifically: `feat: NBLM-x`
  / `fix: NBLB-y` / `fix: NBLM-x` commits that follow the message pattern
  above and correspond to a real `planning/ROADMAP.md`/`planning/CHANGELOG.md`
  entry, and `chore:` commits for docs/tooling/cleanup changes (including
  edits to this file). This is a deliberate exception to the general rule of
  always asking before committing.
- **Never `git push` without asking first, every time** — this is not
  relaxed by the commit pre-authorization above.
- **Notion is the live data source — there is no sandbox workspace.** Unlike
  an app with a separate dev database, every write this app makes (adding a
  scanned book, confirming a genre, editing metadata) lands directly on
  Yann's real Notion `Books`/`Authors`/`Genres` pages, the same ones his
  actual library is cataloged in. Be deliberate about write paths exercised
  during development — prefer testing against a disposable test book entry
  rather than real library data where practical, and don't assume "it's just
  a dev run" makes a write harmless.

## Versioning

Flutter/Dart versioning: `pubspec.yaml`'s `version:` field, format
`MAJOR.MINOR.PATCH+BUILD` (semver plus a platform build number — `BUILD`
becomes Android's `versionCode` / iOS's `CFBundleVersion`). Starting point
for this app: **`0.0.1+1`**.

- **Not bumped automatically per commit.** Bumping is on-demand — do it when
  Yann asks, or naturally once at the end of a session with real changes.
- Bump by the highest-precedence change type since the last `chore: bump
  version to X.Y.Z+N` commit: any `feat:` → **minor** (patch resets to `0`);
  otherwise any `fix:`/`chore:` → **patch**. Nothing since the last bump →
  nothing to do. **Major** is never auto-detected — only on Yann's explicit
  request (resets minor and patch to `0`). The build number (`+N`)
  increments by 1 on every bump regardless of type.
- Single file to edit (`pubspec.yaml`) — no multi-package lockstep sync
  needed here.
- The bump itself is its own `chore: bump version to X.Y.Z+N` commit,
  covered by the same commit pre-authorization as any other `chore:` commit.
- Applies going forward from the `0.0.1+1` baseline.

## Internationalization

Real i18n, not a hardcoded placeholder: Flutter's own `intl`/ARB tooling
(`flutter_localizations` + `generate: true` in `pubspec.yaml`, config in
`l10n.yaml`). Every user-facing string lives in `lib/l10n/app_en.arb` /
`lib/l10n/app_fr.arb`, keyed the same in both files; `flutter gen-l10n`
(auto-run by `flutter pub get`/`flutter run`) produces
`lib/l10n/app_localizations.dart` — don't hand-edit the generated file, edit
the ARB source and regenerate.

**Adding a new user-facing string**: add the key to both ARB files (English
in `app_en.arb` is the template — include `@key` placeholder metadata there
if it takes parameters), then reference it via
`AppLocalizations.of(context)!.yourKey` in widgets, or thread an
`AppLocalizations` instance into non-widget code that needs it (extensions
can't reach `BuildContext`, so they take `l10n` as a parameter instead —
same pattern as the sister Habits app).

**Language selection**: French default (matching the sister app and the
same end user), English as the second language — set in `main.dart`'s
`MaterialApp.locale`. Flip this if it turns out to be the wrong default for
this specific app; it was carried over as an assumption, not confirmed with
Yann app-by-app.

Data fields that are themselves user-facing text (e.g. reading status shown
read-only) should be structured/keyed rather than raw strings, so they can
route through the same ARB lookup.

## Theming

- Centralized, token-driven theming per
  `design/design_handoff_shelf/README.md`'s "Design Tokens" table: OKLCH
  values for `--bg`/`--surface`/`--text`/`--muted`/`--border`/`--track`/
  `--dark`, plus 4 selectable accent/secondary theme pairs shared with the
  sister app (terracotta — default, vert & rouge, ambre & ardoise, sarcelle
  & rouille). Lives in `lib/theme/`, not hardcoded per-widget.
- **No accent=good/secondary=bad semantic.** Unlike Habits, Shelf has no
  polarity to carry through the token system — `accent` is just the primary
  action color. Don't invent a good/bad mapping for Shelf data; it doesn't
  have one.
- **Genre color is Shelf's own semantic use of color**: each genre gets a
  fixed hue (`oklch(0.5 0.1 <hue>)`, independent of theme/light-dark mode),
  via `genreColor()`/`genreHues` in `lib/theme/color_tokens.dart`. The genre
  id list currently backing this is the design prototype's 8-genre set —
  see `planning/BACKLOG.md` for the open reconciliation against
  `docs/Backlog shelf.md`'s different 7-genre Notion list; resolve that
  before wiring genre color to real Notion data.
- `AppColorTokens.forTheme` takes a `Brightness`; every neutral token has a
  distinct dark-mode value (ported from the design doc's own dark-mode
  table, not derived from the sister app's — the two differ slightly).
  `accent`/`secondary` are unchanged across brightness.

## Responsive design

It's a phone app — no tablet/desktop layout is required. The hi-fi
screenshots are pinned to one reference frame (iPhone, 402×874); that's a
mockup size, not a target device. Real Android and iOS phones vary in
width, height, and aspect ratio, so layouts need to flex — safe-area
insets, scrollable content instead of fixed offsets, respecting system text
scaling for accessibility — rather than being built to that exact pixel
frame.

## Folder structure

`lib/` is organized by architectural layer (this app is small enough that a
feature-based split isn't warranted yet):

```
lib/
  models/        # Book, Author, Genre, scan-queue item, OCR candidate
  services/      # notion_api.dart, notion_token_storage.dart,
                 # google_books_api.dart, open_library_api.dart,
                 # barcode/OCR scan services, dedupe logic
  repositories/  # mediate between local sqflite cache and Notion service; own the offline queue
  database/      # sqflite schema/migrations
  providers/     # Riverpod providers
  screens/       # one per design screen
  widgets/       # shared UI (shelf grid tile, genre chip, confidence pill)
  theme/         # OKLCH color tokens, typography scale, spacing constants
```

Keep `models/` decoupled from Notion's schema — `services/`/`repositories/`
translate to and from Notion's property shape, so the rest of the app never
depends on it directly.

Repo root also holds `planning/` (`ROADMAP.md`, `CHANGELOG.md`, `BACKLOG.md`,
`features/NBLM-x.md`, `bugs/NBLB-y.md`), `design/` (the finalized design
handoff — read-only reference, not to be edited), and `docs/`
(`Backlog shelf.md` — the active product/pipeline spec).

## Anything else

If a new rule comes up in conversation, add a section for it here in the
same turn — don't defer it to "later" or rely on remembering it next
session.
