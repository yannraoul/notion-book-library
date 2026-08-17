# NBLM-10 — Home screen: real tabs, genre filter sheet, search

## Why

The "All / By genre / Recent" tabs and the search icon on the Home screen
have been purely decorative since NBLM-2 — no tap handlers, no filtering,
no sorting, `_BookGrid` always rendered the full unfiltered list. Yann
asked to wire all of it up: real tab switching, a genre-filter bottom
sheet, a genuine "Recent" sort by when a book was added to the shelf, and
a search bar matching across title/author/subtitle.

## What changed

- **`dateAdded` threaded end-to-end** — there was no "when was this book
  added" concept anywhere before this. Notion returns `created_time` on
  every page automatically; `NotionApi._parseBook` now reads it into a new
  `NotionBookRecord.dateAdded`, `BooksRepository._toBook` passes it to a
  new `Book.dateAdded`, and `createBook` sets it to `DateTime.now()` for
  a book just created (Notion's `createPage` only returns the new id, not
  the full page, so there's no `created_time` to read back). The sqflite
  cache (`books_cache.dart`) stores it as a full ISO-8601 string (not the
  date-only format used for `published_date` — `created_time` carries
  time-of-day, needed to order same-day adds correctly). `app_database.dart`
  bumped to schema version 3 with an `ALTER TABLE books ADD COLUMN
  date_added TEXT` migration.
- **`lib/providers/shelf_filter_provider.dart`** (new) — `shelfTabProvider`
  (`ShelfTab.all/genre/recent`), `genreFilterProvider` (`Set<String>`),
  `shelfSearchQueryProvider`, and `filterAndSortBooks()`, a pure function
  mirroring the design prototype's tab-scoped logic exactly (confirmed by
  reading `Shelf.dc.html` lines 787-793, 645-649): search narrows whatever
  the active tab shows; the genre filter only applies on the "By genre"
  tab (picking genres while on that tab doesn't silently affect All/
  Recent); "Recent" sorts by `dateAdded` descending, everything else
  sorts alphabetically by title.
- **`lib/screens/home_screen.dart`**:
  - `_TabsRow`/`_TabLabel` now real — tapping switches `shelfTabProvider`;
    tapping "By genre" also (re)opens the filter sheet every time, per the
    prototype's `setTabGenre`.
  - New `_GenreFilterSheet` — genre names come live from Notion
    (`NotionApi.queryRelationNames` on the resolved `genresDatabaseId`,
    same call NBLM-9's `GenreConfirmScreen` already uses), not the old
    hardcoded `genreHues` list, so a genre added directly in Notion (e.g.
    "Cyberpunk") shows up here too. Checkboxes filter the grid live as
    you tap them; "Apply" just closes the sheet, matching the prototype
    (no separate commit step).
  - New `_HomeHeader` — tapping the search icon swaps the title row for a
    `TextField` (matching title/subtitle/any author, case-insensitive
    substring) with a close button that clears the query and collapses
    back. No reference behavior existed for this (the prototype's search
    icon is explicitly "decorative" per its own README), so this
    expand-in-place pattern was a judgment call, confirmed with Yann.
  - Grid now distinguishes an empty shelf (`_EmptyState`, the existing
    onboarding/scan-CTA) from a non-empty shelf with a filter/search that
    matches nothing (new small "No books match." message) — previously
    conflating these would have shown the "scan your first book" CTA
    incorrectly on a no-results search.

## Verification

`flutter analyze` and `flutter test` clean. Manually verified end-to-end
on `flutter run -d windows` against Yann's real connected Notion
workspace (not just sample data): confirmed "By genre" opens the sheet
with the live genre list including "Cyberpunk", checkbox toggles filter
the grid live, "Apply" closes and preserves the filter with a correct "No
books match." state when nothing matches, "Recent" re-sorts to a visibly
different set of top-row books than "All" (confirming real re-sorting,
not just re-filtering), and searching "Weir" (an author name absent from
its book's title, "The Martian") correctly filtered to that one book —
confirming the search genuinely matches across fields, not just title.

Caught and fixed one real bug during this same manual pass: the genre
filter sheet initially overflowed vertically (Flutter's black/yellow
hazard-stripe warning) in a small window — fixed by bounding the sheet's
height and making the checkbox list scrollable independently of the
fixed header/Apply button.

The `date_added` migration itself (`onUpgrade` from a real existing
v2 on-disk `app.db`) wasn't exercised — the local dev database was fresh
for this test — so that specific upgrade path is worth watching on the
next real-device run with pre-existing local data.
