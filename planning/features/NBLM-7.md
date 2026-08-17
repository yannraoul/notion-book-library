# NBLM-7 — Barcode/OCR scan pipeline (Google Books/Open Library lookup, dedupe, genre-confirm)

The scan pipeline NBLM-6 deliberately deferred: barcode/cover-photo
capture → Google Books/Open Library lookup → dedupe against the existing
shelf → genre-confirm → save, reusing NBLM-6's Notion write path. Built
on tested ground rather than debugging both the write path and the camera
pipeline at once.

- IN: `lib/services/google_books_api.dart` (`GoogleBooksApi.lookupIsbn`/
  `.search`), `lib/services/open_library_api.dart` (mirrors both, response
  shapes confirmed live against real ISBNs during planning), `lib/services/
  book_lookup_service.dart` (`BookLookupService` — Google Books first,
  Open Library fills gaps when Google Books has no match or is thin;
  `searchText` merges both, de-duped, scored by a token-overlap
  similarity heuristic against the query), `lib/services/genre_matcher.dart`
  (`suggestGenre` — deterministic keyword matching against the fixed
  7-genre list, never auto-confirms). `BooksRepository.findDuplicate`
  (ISBN exact match first, fuzzy title+author fallback).
  `lib/providers/scan_queue_provider.dart` (`QueueItem`,
  `ScanQueueNotifier` — ephemeral per-session queue, not persisted).
  Six new screens under `lib/screens/`: `scan_screen.dart` (barcode/cover
  toggle, single `MobileScannerController(returnImage: true)` serving
  both modes — barcode reads `capture.barcodes`, cover-photo grabs the
  latest frame's `capture.image` on a capture tap and runs
  `google_mlkit_text_recognition` OCR on it), `queue_screen.dart`,
  `ocr_candidates_screen.dart`, `manual_search_screen.dart` (debounced
  live search — the one screen that takes real keyboard input),
  `dedupe_screen.dart`, `genre_confirm_screen.dart`. FAB "Scan a book"
  and the empty-state primary CTA now push `ScanScreen`.
- Known limitation: `BookLookupService`'s confidence-scoring heuristic
  (token overlap between the search query and each candidate's title)
  over-weights author-name tokens when a query mixes title and author
  together (e.g. "Sapiens Yuval Noah Harari" ranked an unrelated
  "Yuval Noah Harari Seti" entry above the correct "Sapiens" match,
  because 3 of the query's 4 tokens are the author's name) — found during
  live testing, not fixed here. Worth tightening if it turns out to bite
  in practice (e.g. weight the title field higher than author tokens).
  `BooksRepository.findDuplicate`'s fuzzy fallback (exact normalized title
  + shared author) is also a deliberately simple rule, not a string-
  distance algorithm — flagged as a possible future tightening, same as
  when it was written.
- OUT: nothing deferred beyond the above — this is the full pipeline from
  the original plan.
- Done: `flutter analyze` clean, `flutter build windows --debug`
  succeeds. Camera capture itself can't run on `flutter run -d windows`
  (`CLAUDE.md`), but everything downstream of "I have a lookup result" was
  live-tested end to end via Manual Search (temporarily re-pointed the
  FAB's scan tile at it for testing, reverted after) against the real
  Google Books/Open Library APIs and Yann's actual Notion workspace: a
  clean match ("Project Hail Mary") went straight to ready, saved
  correctly via the NBLM-6 write path (verified live — correct ISBN,
  page count, author relation, genre relation, and template icon all
  present on the created page); an exact-title match against an existing
  shelf book ("Dungeon Crawler Carl") correctly flagged as a duplicate,
  opened the dedupe screen with real on-shelf vs. this-scan data, "ISBN:
  missing" correctly flagged in red for the existing row, Cancel left it
  unresolved as designed; a title with no fixed-genre match ("Sapiens")
  correctly required genre-confirm, showed the real Open Library subjects
  under "from API," Confirm stayed disabled until a genre was picked.
  **Barcode detection and cover-photo OCR capture themselves are
  unverified until the Codemagic → Sideloadly → iPhone loop** — same
  caveat set up when NBLM-6 split this milestone out.
- Note for Yann: the "Project Hail Mary" entry created during live
  testing is a real, correctly-cataloged book (not a disposable "ZZZ
  Test" entry like NBLM-6's) — it's fine to keep on the shelf, or delete
  it if you'd rather it wasn't there from a test run. Your call.
- Open decisions: none new.
