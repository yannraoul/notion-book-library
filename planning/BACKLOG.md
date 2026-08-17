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

## Open reconciliation: Genre list mismatch

`docs/Backlog shelf.md`'s Notion `Genres` db list (Fantasy, Science-fiction,
Finances, Personal development, Productivity, Business, LitRPG) doesn't match
`design/design_handoff_shelf/README.md`'s 8-genre color list (Fiction,
Sci-Fi, Fantasy, Business, Self-Help, Non-Fiction, Biography, History) baked
into the hi-fi prototype and ported into `lib/theme/color_tokens.dart`'s
`genreHues` map. Needs a real decision — genres are a Shelf-owned Notion
relation, so this has to resolve to one concrete list — before the
genre-confirm screen (NBLM-x, not yet scoped) is implemented.
