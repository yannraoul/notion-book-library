# NBLM-6 — Manual book entry + Notion write path

`NotionApi` was read-only until now — this milestone adds its first write
capability (`POST /v1/pages`), and the one identification method in the
scan pipeline that needs no camera and no external API: manual entry
(design screen 10). It's the foundation the rest of the pipeline
(NBLM-7 — barcode/OCR scan, Google Books/Open Library lookup, dedupe,
genre-confirm) will build on, split out on purpose: the write path is the
riskiest new code in this feature (it writes directly to Yann's live
Notion workspace, no sandbox), and it's fully testable on
`flutter run -d windows` with zero camera involvement, unlike everything
NBLM-7 adds.

- IN: `NotionApi.createPage`/`createBookPage`/`createRelationPage` +
  private property-builder helpers (title/rich_text/number/date/relation/
  external-file) mirroring the existing read-side parsing helpers.
  `BooksRepository.resolveAuthorIds` (case/whitespace-insensitive match
  against existing `Authors*` rows, creates a new row for any name not
  found — authors are create-or-link) and `.resolveGenreIds` (match-only
  against existing `Genres*` rows — the list is fixed/closed, never
  creates a new one, throws if a picked name isn't found) and
  `.createBook` (orchestrates both + the page create + cache write).
  `BooksCache.insertBook` (single-row insert, vs. `writeBooks`' full-table
  replace). `ManualEntryScreen` (`lib/screens/manual_entry_screen.dart`) —
  Title/Subtitle/ISBN+Pages/Date published+Cover URL/Authors (comma-
  separated)/Genres (toggle chips from the fixed 7-value `genreHues`
  list), wired from both the FAB's "Add manually" and the empty-state's
  "or add manually" link (previously both `_showComingSoon` stubs). This
  is the app's first `Navigator.push` — `root_shell.dart` had no routing
  to plug into before this.
- OUT: barcode/cover scanning, Google Books/Open Library lookup, OCR,
  dedupe check, genre-confirm dialog (manual entry bypasses all of these
  by design, same as the prototype spec) — all NBLM-7.
- Deliberate deviations from the design prototype: Cover is a URL text
  field, not a photo-upload "+" button — Shelf has no backend to host an
  uploaded image against, so a URL (which is what Google Books/Open
  Library will eventually hand it anyway) is the only thing that maps to
  the `coverUrl: String?` model field. Save is disabled while the title
  is blank, rather than the prototype's silent no-op on a blank-title
  save.
- Done: `flutter analyze` clean. `flutter build windows --debug` +
  live-tested against Yann's real Notion workspace: opened Manual Entry
  from both entry points, filled every field including two authors (one
  matching the existing "Fabien Cerutti" row, one new — "ZZZ Fake Test
  Author") and the Fantasy genre chip, saved a disposable "ZZZ Test Entry
  — safe to delete" book. It appeared on the Home grid immediately
  (`ref.invalidate(booksProvider)` picked it up) with the correct genre
  color/label and both authors resolved correctly on read-back — strong
  confirmation the relation ids were actually written, since a failed
  resolve would have silently dropped that author from the list.
  Confirmed Cancel discards cleanly (typed text, hit Cancel, grid
  unchanged, nothing written). **Yann: the test entry above ("ZZZ Test
  Entry — safe to delete") and the new "ZZZ Fake Test Author" row need
  manual deletion from Notion — Shelf has no delete capability yet.**
- Open decisions: none new. NBLM-7 (camera scan pipeline) is next, and
  will need the Codemagic → Sideloadly → iPhone loop to verify —
  `mobile_scanner`/OCR can't be exercised on `flutter run -d windows`.

## Same-session fixes

Yann caught, right after this shipped, that books/authors created through
`ManualEntryScreen` were missing the icon every row created from his own
Notion templates already has — `createPage`/`createBookPage`/
`createRelationPage` only ever wrote `properties`, never `icon`. Checked
live against his workspace (`GET`/`PATCH` via `notion_token.local`):
existing `Books*` rows carry `icon: {type: "icon", icon: {name:
"book-closed", color: "gray"}}`, existing `Authors*` rows carry `icon:
{type: "icon", icon: {name: "user", color: "gray"}}` — Notion's built-in
vector icon set, not emoji/file. Confirmed live via a direct `PATCH` that
the pinned `2022-06-28` API version still accepts setting `icon.type:
"icon"` even though that's a newer Notion feature. Fix: `createPage`
takes an optional `icon` map, `createRelationPage` always passes the
`user` icon, `createBookPage` always passes the `book-closed` icon — both
as `static const` maps on `NotionApi` matching what's actually on Yann's
templates. The two disposable test rows from this milestone's live
verification were archived via the API directly (reversible via Notion's
trash) rather than left for manual cleanup.

