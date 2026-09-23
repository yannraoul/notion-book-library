# NBLM-14 — Wishlist status on new-book creation

## Why

Yann added a new "Wishlist" option to the `Books*` database's `Status`
property, for books he's found but not yet bought (e.g. spotted at a
library). He wanted the add-book flow to optionally save a new book with
`Status = Wishlist` instead of leaving it blank (the pre-existing
default), without adding any extra tap to the default (non-wishlist) flow.

`Status` (along with Current page, Date started, Date finished, Rating)
is otherwise exclusively Habits-owned — Shelf displays it read-only and
never writes it (see `CLAUDE.md`/`docs/Backlog shelf.md`'s ownership
table). This milestone carves out exactly two narrow, explicit exceptions
rather than loosening that boundary generally:

1. Writing `Status = Wishlist` at creation time, and only that value.
2. The single `Wishlist` -> `To read` transition on an existing book (an
   explicit "mark as bought" action) — Yann's own framing: this isn't a
   reading-progress change (still entirely Habits' domain), it's the
   completion of a cataloging event, going from "found but not owned" to
   "owned and on the shelf".

No other status value or transition is ever written by Shelf.

## What changed

- **`lib/models/book.dart`**: `BookStatus` gained a `wishlist('Wishlist')`
  value.
- **`lib/services/notion_api.dart`**: `createBookPage` gained an optional
  `initialStatus` param — omitted (`null`, the default) reproduces the
  exact pre-NBLM-14 payload (no `Status` key at all); passed, writes
  Notion's `status`-type property shape (`{"status": {"name": "..."}}`,
  confirmed live against Yann's schema — distinct from `select`'s shape).
  New `markBookAsAcquired(token, pageId)` — a separate, narrowly-named
  method (not a widened `updateBookPage`) that always writes exactly
  `Status: "To read"`. `updateBookPage` itself is untouched.
- **`lib/repositories/books_repository.dart`**: `createBook` threads
  `initialStatus` through and reflects it in the returned in-memory `Book`.
  New `markBookAsAcquired(token, book)` — asserts the book is currently
  `wishlist` before calling the API, then returns the updated `Book` via
  `Book.copyWith` (new method) and updates the local cache.
- **`lib/providers/scan_queue_provider.dart`**: new `wishlistModeProvider`
  (`StateProvider<bool>`, default `false`) — batch-level, not per-item.
  `commitReady` gained `asWishlist` (default `false`), applied uniformly
  to every item committed in that batch.
- **`lib/screens/queue_screen.dart`**: new "Adding as: To read / Wishlist"
  pill toggle above the queue list (`_StatusModeToggle`, same structural
  pattern as `scan_screen.dart`'s `_ModeToggle` but token-driven). Resets
  to "To read" every time the screen is entered, so a session never
  silently inherits a previous session's choice. "Add ready now"'s
  position/behavior is otherwise unchanged.
- **`lib/screens/manual_entry_screen.dart`**: secondary "Save to wishlist"
  button below the primary "Save book" button, reusing `_save` (now takes
  `asWishlist`) — no duplicated save logic.
- **`lib/screens/book_detail_screen.dart`**: the read-only "Reading
  status" card shows a "Mark as bought" button only when
  `Status == wishlist`; tapping it calls
  `BooksRepository.markBookAsAcquired` and updates local state so the
  button disappears once the status flips. Every other status value keeps
  rendering as plain read-only text with no button, unchanged.
- New l10n keys in both `app_en.arb`/`app_fr.arb`: `queueModeToRead`,
  `queueModeWishlist`, `saveToWishlist`, `markAsBought`.

## Verification

`flutter analyze` clean. `flutter test` — all 14 tests pass. Live-checked
(via `GET /v1/databases/{id}` against Yann's actual `Books*` schema,
using the token in `notion_token.local`) that the `Status` property is
Notion's `status` type with an option named exactly `Wishlist` (grouped
under "To-do" alongside "To read"), matching what the code writes — no
mismatch found.

Not yet independently verified in this environment: exercising the queue
screen's toggle via an actual barcode scan (camera-dependent, per
`CLAUDE.md` — needs a real device) and the corresponding live Notion
writes/round-trip. Deferred to Yann trying it on a real device when he
has time.
