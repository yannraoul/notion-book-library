# NBLM-13 — Pull-to-refresh on the shelf grid + delete book

## Why

Yann edits the `Books*` database directly in Notion in parallel with using
the app (not just through Shelf's own write paths). `booksProvider` only
ever (re)fetches on app start/reconnect, so a change made straight in
Notion wouldn't show up without a full app restart. Separately, the book
detail screen (NBLM-12) could edit every Shelf-owned field but had no way
to remove a book from the shelf at all.

## What changed

- **`lib/screens/home_screen.dart`**: the connected-state body is now a
  `RefreshIndicator` wrapping a single `CustomScrollView`, so a pull-down
  gesture re-runs `ref.refresh(booksProvider.future)` regardless of which
  state (loading/error/empty/grid) is currently showing. This required
  converting each `booksAsync.when` branch into slivers instead of a plain
  widget tree — non-grid states (`loading`, `error`, empty, no-results) use
  `SliverFillRemaining(hasScrollBody: false, ...)` so they always fill the
  viewport and stay draggable even when their content is shorter than the
  screen; the old `_BookGrid` (a `GridView.builder`) became
  `_BookGridSliver` (`SliverPadding` + `SliverGrid`) so it can sit in the
  same `CustomScrollView` as the other branches. `physics:
  AlwaysScrollableScrollPhysics()` on the `CustomScrollView` so the pull
  gesture works even when content doesn't overflow the viewport.
- **`lib/services/notion_api.dart`**: new `archiveBookPage` — `PATCH
  /v1/pages/{id}` with `archived: true`. Notion's REST API has no
  hard-delete; archiving is exactly what Notion's own UI "Delete" does
  (moved to trash, recoverable there from Notion directly), which is the
  right semantics for an app with no sandbox workspace (per
  `instructions.md`'s live-data warning).
- **`lib/repositories/books_repository.dart`**: new `deleteBook(token,
  book)` — calls `archiveBookPage` then drops the row from the local
  `sqflite` cache via a new `BooksCache.deleteBook(id)`.
- **`lib/screens/book_detail_screen.dart`**: edit mode gained a "Delete
  book" text button (icon + `tokens.alert`-colored label) below the
  reading-status card, only visible while `_editing`. Tapping it shows a
  confirmation `AlertDialog` (styled with the app's color tokens, not
  Material defaults) naming the book and explaining the archive-not-erase
  semantics, before calling `BooksRepository.deleteBook` and popping back
  to the shelf on success. Reuses the existing `_saving` flag so the
  Cancel/Save header buttons are disabled during the delete call too.
- New l10n keys in both `app_en.arb`/`app_fr.arb`: `detailDelete`,
  `detailDeleteConfirmTitle`, `detailDeleteConfirmMessage` (takes the
  book's title as a placeholder), `detailDeleting`, `detailDeleteError`.

## Verification

`flutter analyze` clean. Smoke-tested via `flutter run -d windows`: app
builds and launches without a startup crash from the `CustomScrollView`/
`RefreshIndicator` refactor (confirmed the process stays alive, then closed
it). Full interactive verification (dragging to refresh against a live
Notion edit, confirming delete round-trips and the book disappears from
both Notion and the shelf) needs Yann on a connected session — not
independently verifiable without a live Notion token in this environment.
