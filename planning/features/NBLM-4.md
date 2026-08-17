# NBLM-4 — Real Notion-backed book data

Replaced NBLM-2's 6 hardcoded sample books with real reads from Yann's
`Books*`/`Authors*`/`Genres*` databases. Read-only — Shelf never writes
`Status`/`Current page`/`Date started`/`Date finished`/`Rating`, this
milestone or any future one, that's permanently Habits' Reading module's
job. Database IDs are resolved (exact title match) as part of
`notionConnectionProvider`'s connect flow, same point the sister Habits
app resolves its own.

**Live schema was checked directly** against the real databases (same
shared "Perso" workspace the sister app's Reading module already reads/
writes) before writing any parsing code — confirmed `Pages` (not `Page
count`/`Progress`, Habits' own formula fields) is the real total-page-count
property, and `API categories/subjects` already exists on `Books*`,
matching `docs/Backlog shelf.md`'s mapping table exactly.

**Resolved NBLM-1's open genre-list reconciliation item**: real `Genres*`
rows are LitRPG, Fantasy, Science-Fiction, Finances, Personal Development,
Productivity, Business — `docs/Backlog shelf.md`'s original list, not the
design prototype's placeholder 8-genre set. `color_tokens.dart`'s
`genreHues` now keys directly off these real names (with a hash-fallback
for anything unmapped), and `lib/models/genre.dart` (the old l10n-lookup
helper) was deleted — genre names are Notion user data, not app copy.

Implementation is a close port of the sister app's own `notion_api.dart`/
`books_repository.dart`/`books_cache.dart`/`book.dart` (that code is
already proven-correct against this exact real data via its Reading
module, NHTM-20+), trimmed to what Shelf owns/reads.

- IN: `NotionApi.queryBooks`/`queryRelationNames` + parsing helpers,
  `lib/database/app_database.dart` + `books_cache.dart` (sqflite
  offline-read cache, Windows FFI-initialized), `BooksRepository`
  (`resolveDatabaseIds`, `loadBooks` — Notion-first, cache-fallback),
  `notionConnectionProvider`'s `NotionConnected` gains the 3 resolved
  database ids, `booksProvider` is now a real `FutureProvider<List<Book>>`,
  `HomeScreen` gains a connection-gated `_NotConnectedState` (distinct from
  "shelf is empty") plus loading/error handling, `Book` model restructured
  for real data (`authors: List<String>`, `coverUrl`, `apiCategories`,
  `publishedDate: DateTime?`).
- OUT: writes of any kind (scan/manual-entry/dedupe are separate future
  milestones), book detail screen, cover-image rendering (grid tiles stay
  flat genre-color blocks per the design's own stated intent — "real cover
  art to be swapped in later" — `coverUrl` is parsed and cached now but
  unused in UI), persisted-database-id-preference/cache-fallback polish
  (the sister app's later NHTM-18 refinement, not needed yet).
- Done: `flutter analyze` clean. Live-tested on `-d windows` against the
  real token: not-connected prompt renders correctly before connecting;
  after connecting, the real library loads and renders with correct
  genre-tile colors (cross-checked against a raw API dump — e.g. the
  "Bâtard de Kosigan" LitRPG entries render in the LitRPG hue).
- Open decisions: Notion's `Cover` file URLs are signed and expire (~1hr) —
  caching `coverUrl` verbatim means a cached value can go stale before it's
  ever rendered; not a problem yet since nothing displays it, but whichever
  milestone adds cover-image rendering needs to either re-fetch on display
  or treat the cached URL as potentially dead. `pages` converts Notion's
  `number` (double) to `int` via `.round()` at the repository boundary —
  fine for whole-number page counts, would lose precision if that ever
  changed.
