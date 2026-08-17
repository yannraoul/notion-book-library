# NBLM-9 — Genre: live from Notion, create-or-link like authors

## Why

NBLM-4 baked the `Genres*` picker into a fixed, hardcoded 7-entry map
(`genreHues` in `lib/theme/color_tokens.dart`), on the assumption the
Notion `Genres*` database's list wouldn't change independently of the
app. That assumption broke: Yann added "Cyberpunk" directly in Notion, and
the app had no way to discover it — worse, `BooksRepository.resolveGenreIds`
*threw* if a confirmed genre name didn't match the fixed list, because
genres were deliberately designed as create-*never* (unlike authors,
which were already create-or-link since NBLM-6). There was also no way to
add a brand-new genre from the app at all.

## What changed

- **`GenreConfirmScreen`** (`lib/screens/genre_confirm_screen.dart`) now
  fetches the live `Genres*` list on open via
  `NotionApi.queryRelationNames` (already used for the same purpose in
  `BooksRepository.loadBooks`) instead of iterating `genreHues.keys`.
  Falls back to the static list only if the live fetch fails (offline,
  connection error) — same live-first/fallback pattern already
  established for book loading. `genreColor()` already had a hash-derived
  fallback hue for any name not in `genreHues` (confirmed reading
  `color_tokens.dart` — this was already future-proofed), so a newly
  live-fetched genre like "Cyberpunk" gets a distinct, deterministic color
  with no changes needed there.
- Added a plain text field below the genre chips — typing a name that
  doesn't match an existing chip becomes the selection directly (no
  separate "create genre" confirmation step, per Yann's explicit call:
  auto-create like authors).
- **`BooksRepository.resolveGenreIds`** rewritten to mirror
  `resolveAuthorIds` exactly: case/whitespace-insensitive match against
  existing `Genres*` rows, create a new row via the new
  `NotionApi.createGenrePage` for anything unmatched, instead of throwing.
  The actual Notion write only happens later, at `commitReady()` →
  `createBook()` time (confirming a genre on the queue item is still just
  local state until the book is actually saved) — so typing a new genre
  and hitting Confirm has zero extra Notion calls until the existing
  "Add ready now" write path runs, same as it already worked for authors.
- New `NotionApi.createGenrePage` uses the same built-in-icon shape as
  `_bookIcon`/`_authorIcon` — `tag`/`gray` — per Yann's explicit call
  (no emoji). Unlike `book-closed`/`user`, this slug name isn't
  live-confirmed against his workspace; a genuine Notion icon-picker
  wasn't available to verify it against, so if `tag` turns out invalid the
  first genre auto-create will fail loudly (a `createPage` 400) rather
  than silently — worth watching for on first real use.

## Verification

`flutter analyze` and `flutter test` both clean. The actual Notion
read/write (live genre fetch, and creating a new `Genres*` row on first
use of a new name) is not locally verified — needs a real run against
Yann's workspace, same constraint as the rest of the write path since
there's no sandbox Notion workspace (`instructions.md`).
