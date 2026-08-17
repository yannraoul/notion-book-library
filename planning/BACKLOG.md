# Backlog: ideas not yet scoped into a milestone

Raw ideas that are worth keeping around but haven't been committed to as a
concrete unit of work. Once one of these is actually scoped and started, it
graduates into `ROADMAP.md` with its own **NBLM-x** identifier and moves out
of this file. See `../instructions.md` for how the three planning docs
(`ROADMAP.md` / `CHANGELOG.md` / `BACKLOG.md`) relate.

## Explicitly out of scope for v1

From `docs/Backlog shelf.md`'s original spec — deliberately deferred, not
forgotten:

- **LLM-based cover recognition/guessing.** Skipped on purpose to avoid
  overlapping Art Explorer's key usage — the scan pipeline is barcode + Google
  Books/Open Library + on-device OCR only, no LLM calls.
- **Author bio/photo.** Neither Google Books nor Open Library exposes this
  well; would need a third data source.
- **Rating import from external sources.** Ratings stay owned by Habits
  (read-only in Shelf) — no external rating API integration planned.

## Resolved: genre list mismatch

Was: `docs/Backlog shelf.md`'s Notion `Genres` db list didn't match the
design prototype's 8-genre color list baked into `color_tokens.dart`.
Resolved by NBLM-4 — checked the real `Genres*` database live, it matches
`docs/Backlog shelf.md`'s original list exactly (LitRPG, Fantasy,
Science-Fiction, Finances, Personal Development, Productivity, Business).
`genreHues` now keys off these real names.
