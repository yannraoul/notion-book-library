# NBLM-12 — Book detail screen + author duplicate-prevention

## Why

Book detail (design screen 10) was the one screen of the 13-screen spec
never built — there was no `book_detail_screen.dart`, and tapping a cover
in the home grid went nowhere. Building it surfaced a real data-integrity
gap: `Book.authors` is free text, and the only author-identity logic in the
app (`BooksRepository.resolveAuthorIds`) matches existing `Authors*` rows by
exact string equality after `trim().toLowerCase()`. Variant forms of the
same author's name (e.g. "F. C. Yee" vs "F.C. Yee" vs a spelled-out given
name) would each silently create a separate `Authors*` row in Notion, with
no way to notice or correct it. Yann asked for this closed off everywhere a
book's authors can be entered or edited, not just on the new screen — so
this milestone covers three entry points: book detail (new), manual entry
(pre-existing free-text field with the same exposure), and the scan-import
pipeline (which already gates genre on a suggest-then-confirm step, but had
no equivalent for authors).

## What changed

- **`lib/services/author_matcher.dart`** (new) — the name-vs-name
  similarity logic that everything else is built on. Deliberately separate
  from `genre_matcher.dart`, which is a different problem shape (raw
  category text → fixed 7-entry keyword list, not name-vs-name against live
  data). Normalizes punctuation/whitespace and "Last, First" ordering;
  `isExactMatch` is the only silent/auto-link path (same semantics as
  today's `resolveAuthorIds`, plus the comma-reorder case folded in).
  Non-exact pairs get a surname-anchored continuous score: a low surname
  similarity forces the score down regardless of given-name agreement
  (different last name ⇒ treat as unrelated); given-name tokens get full
  credit for exact matches, ~0.85 credit when one side is a bare initial
  and the other's given name starts with that letter (the "F." vs "Fonda"
  case), and a Levenshtein ratio otherwise. Confidence bands: `>=1.0` exact
  (only reachable via `isExactMatch`), `>=0.55` ambiguous (needs
  confirmation), below that: no match, treated as new — silent, unchanged
  from today. `rankAuthorMatches`/`resolveAuthorMatch` are the two entry
  points every consumer below uses. Covered by
  `test/services/author_matcher_test.dart` (worked examples: "F. C. Yee" vs
  "Fonda C. Yee" → ambiguous ~0.96; "Smith" vs "John Smith" → ambiguous
  0.75; "John Smith" vs "John Smithson" → none, different surname; a plain
  typo → ambiguous; identical strings → exact).
- **`lib/providers/authors_provider.dart`** (new) — `authorNamesProvider`,
  a live `id -> Name` fetch of `Authors*` via the existing
  `NotionApi.queryRelationNames`, shared by every consumer below instead of
  each one fetching ad hoc. Invalidated after `commitReady` in
  `queue_screen.dart` alongside the existing `booksProvider` invalidation.
- **`lib/widgets/author_chip_input.dart`** (new) — the shared chip/tag
  input: type a name, get a live-matched, confidence-ranked dropdown (or
  "add as new"), pick one, confirmed names become removable chips. Never
  calls `createRelationPage` itself — it only ever produces/consumes a
  plain `List<String>` of display names, identical in shape to the old
  comma-separated text it replaces; actual `Authors*` page creation stays
  exclusively inside `resolveAuthorIds` at save/commit time.
  **Deliberate deviation from the design spec**: screens 09/10 specify
  Authors as a single full-width free-text field. Yann confirmed a chip
  input instead, explicitly accepting the visual deviation, since the
  duplicate-prevention UX needs more structure than a bare text field can
  give.
- **`lib/screens/book_detail_screen.dart`** (new) — the actual screen,
  **read-only by default** (per Yann's explicit follow-up ask, to avoid a
  stray tap editing a Notion field by accident): plain text/badges
  everywhere, an "Edit" button top-right next to "‹ Back". Tapping it
  switches every Shelf-owned field to a draft — inline-editable title,
  `AuthorChipInput`, a cover-URL text field (pre-filled with the current
  URL, so a bad/low-res/expired cover can be replaced by hand), ISBN/Pages/
  Published as right-aligned inline fields, Genres as the full chip-toggle
  grid (live-fetched the same ad hoc way `GenreConfirmScreen` already
  does) — and swaps the header to "Cancel" (discards the whole draft) /
  "Save" (writes every changed field in one `BooksRepository.updateBook`
  call). Below that, a `tokens.dark`-filled "Reading status" card is
  **never** part of the draft and never editable in either mode: it shows
  Status/Current page as plain text always, and the write path
  (`BooksRepository.updateBook`) has no parameter for any Habits-owned
  field at all, so there's no way to wire one through even by accident.
  Wired into navigation from `home_screen.dart`'s grid tile tap.
- **`lib/services/notion_api.dart`**: new `updateBookPage` (`PATCH
  /v1/pages/{id}`, only non-null fields sent) — no update/PATCH method
  existed before this milestone, only `createPage`/`createBookPage`/
  `createRelationPage`/`createGenrePage`.
- **`lib/database/books_cache.dart`**: new `updateBook` using `db.update`
  — `insertBook`'s `db.insert` would throw on this row's existing primary
  key.
- **`lib/repositories/books_repository.dart`**: new `updateBook`, the book
  detail screen's write path — every field optional, resolves
  authors/genres through the existing unchanged `resolveAuthorIds`/
  `resolveGenreIds` only when provided, carries `current.reading` through
  untouched.
- **Scan-import pipeline** (`lib/providers/scan_queue_provider.dart` +
  friends): new `QueueItemStatus.needsAuthorConfirm`, mirroring
  `needsGenre`'s shape but inverted — it fires when a scanned author name
  is *ambiguous* against `Authors*` (not when nothing matches; a clean
  no-match still silently becomes a new author, same as today). Status is
  now computed through one shared priority-chain helper
  (`_computeStatus`: duplicate > needsAuthorConfirm > needsGenre > ready)
  so resolving one axis correctly reveals the next pending one instead of
  jumping straight to `ready`. New `ScanQueueNotifier.confirmAuthor`
  rewrites a queue item's raw author name to the canonical existing one
  (or keeps it as-is for "new"), which is what makes `resolveAuthorIds`'s
  exact-match logic sufficient at commit time (see below). New
  `lib/screens/author_confirm_screen.dart` mirrors `GenreConfirmScreen`'s
  live-fetch structure but shows ranked candidates with confidence pills
  per ambiguous author (reusing the same visual language as the OCR
  ranked-list screen) instead of a flat chip grid. `queue_screen.dart`'s
  status→label switch and tap-routing switch both extended for the new
  status.
- **Manual entry** (`lib/screens/manual_entry_screen.dart`): the old
  `_authorsController` comma-separated `TextField` replaced with
  `AuthorChipInput`.
- **Shared widget extraction** (prerequisite refactor, `lib/widgets/`):
  `GenreChip` (was duplicated verbatim in `genre_confirm_screen.dart` and
  `manual_entry_screen.dart`, now also used by book detail),
  `ConfidencePill` (extracted from `ocr_candidates_screen.dart`, also used
  by the chip-input dropdown and author-confirm screen), `BookCover`
  (extracted from `home_screen.dart`, parameterized by width/height so it
  can also render book detail's fixed-size hero cover).
- **`BooksRepository.resolveAuthorIds` is deliberately left unchanged.** By
  the time it runs (manual entry's Save, or the queue's `commitReady`),
  every ambiguous case has already been resolved upstream — either through
  `AuthorChipInput`'s explicit pick/add-as-new, or through
  `AuthorConfirmScreen`'s `confirmAuthor` rewriting the name to the
  canonical existing string. Its exact-match-after-normalize behavior is
  exactly the right, narrow final step at that point.
- **`lib/services/notion_api.dart`/`books_repository.dart`**:
  `updateBookPage`/`updateBook` also take an optional `coverUrl`, writing
  the `Cover` external-file property — the book-detail cover-edit field's
  write path.
- New l10n keys in both `app_en.arb`/`app_fr.arb`: `statusNeedsAuthor`,
  `authorChipHint`, `authorAddNew`, `authorConfirmTitle`,
  `authorConfirmKeepNew`, `detailEdit`.

## Round-2 fixes from live feedback

After the first live pass, Yann asked for five changes, all applied and
re-verified live against his real workspace:

- **Author chips inline with the input**, not stacked as a separate row
  above it — `AuthorChipInput` now renders removable chips and the text
  field inside one bordered box (`Wrap` + `IntrinsicWidth`-constrained
  `TextField` with no border of its own), a single input line instead of
  two.
- **Autocomplete wasn't surfacing anything except "add as new."** Root
  cause: `rankAuthorMatches` is deliberately built for catching
  near-duplicate *spelling variants* of a full name (surname-anchored), not
  general typeahead — typing "james" against an existing "James Clear"
  scores `none`, because with only one token typed there's no surname to
  anchor on. Fixed by giving the dropdown two independent sources: a plain
  substring/prefix filter over the live `Authors*` list (normal typeahead —
  what was missing) shown first, plus `rankAuthorMatches`'s near-duplicate
  results (with a confidence pill) for names a substring search wouldn't
  catch, e.g. "Dinimann" → "Dinniman". Deduped, capped at 5.
- **Back button was centered, not left-aligned like every other screen.**
  Real layout bug, not styling: the button was a direct child of the
  screen's `ListView`, and `SliverList` gives each child a *tight* (not
  loose) cross-axis width constraint — full viewport width — so
  `TextButton`'s default `Alignment.center` centered its label inside that
  forced-full-width slot. Every other screen avoids this by keeping its
  header row (Cancel/Back, title, Save) outside the scrollable list, in a
  plain `Row`/`Padding` above it, where children get loose width and hug
  their own content. Moved book detail's header out to match.
- **Read-only by default, with an explicit Edit action** — see the
  `book_detail_screen.dart` bullet above. This also replaced the original
  per-field save-on-blur/save-on-toggle model with a single batched
  Cancel/Save, which is a real behavior change worth flagging: editing
  three fields then hitting Cancel now discards all three, where the
  original per-field autosave would have already written the first two to
  Notion.
- **Cover editing** — no way existed to fix a cover that resolved to a
  poor-resolution image or a dead URL. Edit mode now shows a "Cover" URL
  field under the hero image, pre-filled with the current URL (Notion's
  own signed S3 URL if the cover came from a `Books*` upload, or whatever
  external URL was set), editable like any other field and included in the
  batched Save.

## A bug found and fixed during live verification

Live-testing `AuthorChipInput` against Yann's real Notion workspace (typing
"Matt Dinimann" against the real "Matt Dinniman" — confirmed the matcher
correctly surfaced an 88% candidate) turned up a real interaction bug:
tapping a candidate row did nothing — the dropdown vanished and the raw
typed text was left in place. Root cause: the dropdown's visibility was
gated on the text field's `FocusNode.hasFocus`, but a candidate row is
itself a focusable widget (`InkWell`), so tapping it shifts primary focus
away from the text field *before* the row's own `onTap` fires — the
dropdown unmounted mid-gesture and the tap was lost. Fixed by making
visibility query-driven instead (an explicit `_dismissed` flag) and using a
`TapRegion.onTapOutside` to close the dropdown on a genuine tap elsewhere,
rather than tying it to focus state. Re-verified live against the same real
author name after the fix — the candidate is now added as a chip correctly.

## Verification

`flutter analyze` and `flutter test` both clean (13 tests, including 10 new
in `author_matcher_test.dart`). Live-verified via `flutter run -d windows`
against Yann's real Notion workspace across both passes: home grid → book
detail renders correctly (hero cover, editable title, author chips,
metadata card, genre toggle, read-only reading-status card with no input
affordance); editing and reopening confirmed the Notion write round-trips
correctly; manual entry's `AuthorChipInput` surfaced a real 88%-confidence
candidate for a near-match name and added it as a chip on selection (after
fixing the tap-vs-focus bug above). Round 2: confirmed the read-only view
renders plain text/badges with no editable chrome, Edit correctly reveals
the draft form (inline author-chip box, cover-URL field pre-filled with
the real signed S3 URL, full genre grid), Cancel discards without writing,
Save writes and returns to read-only, "‹ Back" is left-aligned again, and
typing "ja" in the author field surfaced real substring matches ("James
Lucano", "Jean-Philippe Jaworski") from Yann's live `Authors*` list.

**Not locally verifiable**: the scan-import side of author-matching
(`QueueItemStatus.needsAuthorConfirm`, `AuthorConfirmScreen`) only gets
real input from the barcode/OCR pipeline, which needs a camera —
`flutter run -d windows` can't exercise it, same constraint noted in
NBLM-7. As a partial substitute, Manual Search already routes through the
same `addFromLookup` call the barcode/OCR paths use, so it could exercise
the new author-gating logic end-to-end without a camera if needed; full
verification (reaching `AuthorConfirmScreen` from a real scan) needs Yann
on a real Android/iOS device.
