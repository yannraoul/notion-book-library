# Backlog — Shelf

**Status:** backlog, unscoped into milestones yet. New app.

**Purpose:** book library management — add, identify, enrich metadata,
dedupe. Never touches reading progress or status. Reading progress and
status live in a separate app (Habits, Reading module) against the same
Notion `Books` database; this app only owns cataloging/metadata
properties.

**Why a dedicated app (not an MCP skill):** the value is in the
scan-to-catalog pipeline and browsing UX (shelf view, genre filter,
duplicate detection at add-time), not just data capture. Existing MCP
infra + Claude's camera access already cover ad-hoc capture; this needs a
purpose-built fast-add flow.

## Property ownership (Notion `Books` db)

Shelf owns — writes:

- `Name` (title)
- `Subtitle`
- `Authors` (relation — creates/links `Authors` db rows)
- `ISBN`
- `Genres` (relation — suggested from API data, user-confirmed before
  write)
- `Cover`
- `Date published`
- `Pages` (total page count, from publisher metadata)
- `API categories/subjects` (raw string dump, reference only — not the
  curated `Genres` relation)

Read-only (displayed for convenience, never written): `Status`,
`Current page`, `Date started`, `Date finished`, `Rating`.

`Authors` db (Name + Books relation) and `Genres` db (Fantasy,
Science-fiction, Finances, Personal development, Productivity, Business,
LitRPG) are Shelf-owned.

## Pipeline (no LLM — deliberately, to avoid overlapping Art Explorer's
key usage)

1. **Barcode scan** (`mobile_scanner`) → ISBN → **Google Books API**
   lookup (primary, no key required for basic volume search) → **Open
   Library API** fallback (`/api/books?bibkeys=ISBN:...`) if no match or
   thin data.
2. **No barcode / bad cover photo** → on-device OCR
   (`google_mlkit_text_recognition`, offline, free) extracts title/author
   text → fed as a text query to Google Books search, then Open Library
   search as fallback.
3. **Both fail** → manual entry form (all Shelf-owned fields, blank).
4. **Dedupe check** against existing `Books` db before writing: match by
   ISBN first, fallback to fuzzy title+author match. Surface as
   "possible duplicate, confirm add anyway / merge / cancel."
5. **Genre resolution:** API `categories` (Google) / `subjects`
   (OpenLibrary) written verbatim to `API categories/subjects` (reference
   only). Cross-check against existing `Genres` db values and suggest a
   match; user confirms or picks manually before the `Genres` relation is
   written. Never auto-write an unconfirmed genre relation — the source
   data is too noisy/inconsistent to trust blind.

## API → Notion field mapping

| Notion field | Google Books (`volumeInfo`) | Open Library |
|---|---|---|
| Name | `title` | `title` |
| Subtitle | `subtitle` | `subtitle` |
| Authors | `authors[]` | `authors[].name` |
| ISBN | `industryIdentifiers` (ISBN_13 preferred) | `isbn_13` / `isbn_10` |
| Pages | `pageCount` | `number_of_pages` (edition-specific via ISBN endpoint; Search API gives a median — avoid that path) |
| Cover | `imageLinks.thumbnail`/`small` | `covers[]` → cover ID → image URL |
| Date published | `publishedDate` | `publish_date` |
| API categories/subjects | `categories` (single highest-weight category) | `subjects[]` (can be long/noisy, cap what's stored) |

Google Books first (cleaner category data), Open Library fills gaps
(better coverage on older/obscure titles, no key ever needed).

## Explicitly out of scope for v1

- LLM-based cover recognition/guessing.
- Author bio/photo (neither API exposes this well).
- Rating import from external sources.

## Stack

Flutter/Dart, Android+iOS, Riverpod, `sqflite` offline cache (lower
criticality than Habits — writes are low-frequency — but kept for
scan-then-sync while offline and pattern consistency), Notion API direct
from client (no backend, same single-user justification as Habits, token
in `flutter_secure_storage`, scoped to `Books`/`Authors`/`Genres`
databases only), Codemagic for unsigned iOS builds.

## Visual identity

Shared design system, independent information architecture — handed off
to Claude Design on this basis:

- **Inherit from Habits:** OKLCH token structure, all 4 accent themes
  (terracotta, vert & rouge, ambre & ardoise, sarcelle & rouille),
  dark/light modes, `l10n` setup (English + French, no hardcoded
  strings), shared component primitives (buttons, cards, segmented
  controls) — sourced from
  `design/design_handoff_habit_tracker/`.
- **Diverge from Habits:** layout/IA adapted to Shelf's actual rhythm —
  browse/scan-heavy (shelf grid, scan flow, dedupe-confirm and
  genre-confirm dialogs) vs. Habits' ring/streak-heavy home. Same visual
  vocabulary, different layout grammar — not a reskin of Habits' screens.