# Handoff: Shelf (book cataloging companion app)

## Overview
Shelf is a book-cataloging companion to an existing habit-tracking app ("Habits"). It scans, identifies, deduplicates, and stores metadata for physical books (title, author, ISBN, pages, publication date, genres). Shelf shares Habits' visual design system (color tokens, typography, component patterns) but has its own information architecture and screens. Shelf never owns or edits reading-progress data (status, current page, dates, ratings) — that stays in Habits; Shelf only displays it, read-only, where relevant.

## About the Design Files
The files in this bundle (`Shelf.dc.html`, `ios-frame.jsx`) are **design references built in HTML** — a prototype showing the intended look, content, and interaction flow. They are not production code to copy directly. The task is to **recreate these designs in the target codebase's actual environment** (the existing Habits app is Flutter — see `DESIGN_SYSTEM_habits_reference.md` — so Shelf should most likely be implemented as new screens/widgets in that same Flutter codebase, reusing its theme, widgets, and providers) or, if Shelf ships standalone, in whatever framework is chosen for it.

`Shelf.dc.html` opens directly in a browser (it's a self-contained prototyping format — a template + a small React-like logic class in one file; ignore that machinery, read it as behavior/structure reference). `ios-frame.jsx` is just a cosmetic iPhone bezel used to preview it and is not part of the design itself.

## Fidelity
**High-fidelity.** Colors, typography, spacing, and interaction behavior (state transitions, conditional fields, i18n strings) are intended to be final, built directly from `DESIGN_SYSTEM_habits_reference.md`, the current source of truth for the sister app's design system. Sample book data, the mocked OCR/API results, and the "Jordan's workspace" Notion placeholder are illustrative only.

## Design System Basis
Shelf reuses Habits' token architecture exactly (see the attached `DESIGN_SYSTEM_habits_reference.md` for the full spec — this section only calls out what Shelf-specific work assumed):
- Same OKLCH neutral token set (`bg`, `surface`, `text`, `muted`, `border`, `track`, `dark`, `alert`) with independent light/dark values.
- Same 4 accent/secondary theme pairs (Terracotta default, Vert & rouge, Ambre & ardoise, Sarcelle & rouille), fixed across light/dark.
- Same component vocabulary: card (18px radius, `surface` + 1px `border`), pill/badge (20px radius, soft-tinted bg), segmented control (chip row, not native `Switch`/`SegmentedButton`), checkbox-style circular toggle, primary button (solid accent, white text, full width).
- Same "no AppBar, inline custom header per screen" layout convention, and bottom-nav-only navigation (no drawer/tabs widget).
- Shelf does **not** need the accent=good/secondary=bad semantic mapping from Habits (§1.3 of the reference doc) — Shelf has no positive/negative polarity. Genre cover colors are a new, Shelf-specific use of hue variation (see Design Tokens below) and are not tied to the accent/secondary tokens.

### Bottom navigation
Habits' shell has 5 tabs (Accueil/Stats/Badges/Books/Réglages). Within Shelf's own screens we only show and wire the 2 tabs relevant to this app: **Home** (the shelf/grid root) and **Settings**. In the real app shell, Home corresponds to the existing "Books" tab slot; Stats/Badges/Accueil are other apps' tabs and are out of scope here.

## Screens / Views

### 1. Shelf grid (`02-shelf-grid.png`)
**Purpose**: browse the catalog.
**Layout**: header row — "Shelf" title (28px/700) + circular search icon button (36×36, `border`/`surface`, decorative in this prototype). Tab row (All / By genre / Recent — 15px/600, active = `text` color + 2px `accent` underline, inactive = `muted` + transparent underline), bottom-bordered. 3-column grid (14px gap), each cell: cover block (2:3 aspect ratio, 10px radius, solid genre color, genre label bottom-left in white 10px/600), title (12.5px/600, 1 line ellipsis), author (10.5px, `muted`). Floating "+" button (56×56 circle, `surface` fill, 1.5px `accent` border) bottom-right opens a small menu: "Scan a book" / "Add manually". "By genre" tab opens a bottom sheet with a checkbox list of all genres + Apply.

### 2. Empty / first-run state (`01-empty-state.png`)
**Purpose**: shown when the catalog has zero books — no tabs/filters until there's content.
**Layout**: same header as grid (no tabs). Centered: striped placeholder illustration (SVG diagonal-stripe pattern in `track`/`border`, monospace caption "illustration: empty shelf" — replace with real illustration asset), title (19px/700), message (14px, `muted`), primary button "Scan your first book" (full width, solid `accent`), secondary text link "or add manually".

### 3. Scan flow (`03-scan-initial.png`, `04-scan-2-scanned.png`)
**Purpose**: capture books via camera, batch multiple before reviewing.
**Layout**: full-bleed dark camera area (`#0a0a0a` background, viewfinder panel `#161616`) — this is the one screen that breaks from the light/dark token background since it represents an actual camera feed. Header: "Cancel" (left), running "N scanned" pill (`accent` fill, top-right). Below header: Barcode/Cover photo segmented toggle (white pill when active). Viewfinder: thin horizontal accent scan-line + 4 corner brackets, matching a barcode-scan target. Thumbnail strip (48×48 swatches) below the viewfinder shows already-scanned items. "Review queue (N)" primary button at the bottom, disabled/dimmed at N=0.
**Behavior**: if no barcode is found within ~2.5s of entering Barcode mode with 0 scans, an inline hint appears below the viewfinder: *"No barcode found — try 'Cover photo' above"* — this is a nudge only, never a silent auto-switch to Cover-photo mode. Tapping Cover-photo mode instead routes to the OCR ranked-list screen (a photo capture is assumed to have happened).

### 4. Queue review (`05-queue-review.png`)
**Purpose**: resolve a batch of scanned books before committing them to the shelf.
**Layout**: title "N books scanned", "Cancel" back to scan. List of rows, each tagged with a status: **ready** (accent text, checkmark implied), **duplicate** (alert-red border + text), **needs-genre** ("genre?" in muted text). Tapping a duplicate row opens the Dedupe dialog; tapping a needs-genre row opens Genre confirm. Bottom button: "Add N ready now" — N is the live count of ready items; disabled/greyed when 0. Adding removes ready items from the queue and pushes them to the shelf; if any flagged items remain, the queue screen stays open with the updated count.

### 5. OCR ranked list (`06-ocr-ranked-list.png`)
**Purpose**: cover-photo mode's identification result.
**Layout**: back to scan, title "Which book did you scan?". Each candidate row: small cover placeholder, title/author, confidence % pill (`accent`-tinted). Link at the bottom: "None of these — search manually" → Manual search.

### 6. Manual search (`07-ocr-manual-search.png`)
**Purpose**: fallback when OCR/ranked candidates don't match.
**Layout**: editable text field pre-filled with the raw (often garbled) OCR guess, styled with a 1.5px `accent` border to signal it's the active/important field. Result rows update live as the text changes, each showing a confidence %. Selecting a result adds it to the queue.

### 7. Dedupe dialog (`08-dedupe-dialog.png`)
**Purpose**: resolve a scan that matches an existing shelf entry.
**Layout**: title "Matched by title + author" + "(no ISBN on file to compare)" — this is the **sparse-match** case: the existing record was matched on title+author alone, so its ISBN/pages fields are unknown. Two-column compare: "On your shelf" (existing, sparse — ISBN and Pages both rendered as "missing" in alert-red) vs. "This scan" (new data, complete). Primary action is **"Fill in missing details"** (merges the new scan's data into the existing record — the recommended path since the existing record is incomplete). Secondary: "Add as separate book" (outline button). Tertiary: "Cancel" (plain text, returns to the queue with the item still unresolved).

### 8. Genre confirm (`09-genre-confirm.png`)
**Purpose**: resolve a "needs genre" queue item.
**Layout**: a `select` pre-filled with the suggested genre (bordered in `accent` to draw the eye), with the raw, non-editable API category string shown beneath in small `muted` text ("from API: '...'"). "Confirm" commits the genre and marks the item ready.

### 9. Manual entry (`10-manual-entry.png`)
**Purpose**: add a book without scanning.
**Layout**: modal-style header (Cancel / title / Save, matching Habits' add-item pattern — no bottom nav). Fields, top to bottom: Title (full width), Subtitle (full width), ISBN + Pages (paired, 2 columns), Date published + Cover upload (paired — date input + a small dashed-border upload placeholder), Authors (full width), Genres (chip-toggle grid — tap to add/remove, selected = filled `accentSoft` bg + `accent` border/text). "Save book" primary button.

### 10. Book detail (`11-book-detail.png`)
**Purpose**: view/edit a catalogued book.
**Layout**: "‹ Back" link, hero cover (150×225, genre-colored), title and author rendered as **editable** inline inputs (no visible chrome until focused, then an `accent` underline appears) — Shelf owns and can edit all of this. Metadata card below: ISBN, Pages, Published (each an editable right-aligned inline input) and Genres (chip-toggle grid, same pattern as manual entry). Below that, a **visually distinct** card using the `dark` neutral token as a solid fill (not `surface`) labeled "Reading status (read-only)" showing Status and Current page — these two fields are rendered as plain text, never inputs, because they belong to Habits and Shelf must never write to them.

### 11. Empty state
Covered above as screen 2.

### 12. Onboarding (`12-onboarding-1.png`, `13-onboarding-2.png`, `14-onboarding-3.png`)
**Purpose**: first-launch explanation, reachable again later from Settings → About.
Three screens, each with a progress-dot indicator (3 dots, active = wide `accent` pill) and a "Skip" link (screens 1–2 only):
1. **What Shelf does** — catalog only, not reading progress (that's Habits).
2. **Three ways to add a book** — scan barcode / snap cover photo / type manually (icon + one-line description each).
3. **Duplicates get caught automatically** — ends on two choices: "Scan your first book" (primary, → Scan flow) and "Skip to shelf" (secondary, → Empty state).

### 13. Settings (`15-settings.png`)
**Purpose**: connection status, language, appearance, and app info.
**Layout**: sectioned cards, each with an uppercase `muted` section label above:
- **Notion connection** — monogram icon (34×34, `dark` fill), "Connected to Notion" + workspace name, `accent` status dot, "Reconnect"/"Disconnect" text links.
- **Language** — segmented English/Français.
- **Appearance** — segmented Light/Dark/System (Habits only has Light/Dark; Shelf adds System as a 3rd option since it's a common pattern worth adopting — flag to product if that should be pulled back in line with Habits).
- **Accent theme** — 4 swatch chips (2 dots: accent + secondary, plus theme name), selectable, matching the 4 Habits themes exactly.
- **About Shelf** — short paragraph on what Shelf owns vs. doesn't (echoing the Book detail read-only note), plus a "View onboarding again" link.

## Interactions & Behavior
- **Navigation**: bottom bar has 2 items in this prototype — Home (shelf grid) and Settings — both persisted across the grid, empty, and settings screens; all other screens are pushed (no bottom nav), matching the Habits convention of hiding the tab bar on pushed/form screens.
- **Scan → Queue → resolve → add**: this is the primary flow and is fully interactive in the prototype. Tapping the viewfinder simulates a scan; a fixed 3-item script demonstrates all three queue outcomes (ready, duplicate, needs-genre) in order.
- **Dedupe merge**: "Fill in missing details" takes the new scan's ISBN/pages/published and writes them onto a newly-created shelf record (in a real backend, this would update the existing record in place rather than create a new one — the prototype's local state doesn't model a separate "existing record" store).
- **Genre confirm**: does not close/commit until "Confirm" is tapped; the select's live value is local state, not written until then.
- **Manual entry / detail editing**: all fields are plain controlled inputs; saving with an empty title is treated as a no-op (screen closes without creating a book) — same "empty save closes without creating" behavior Habits uses for its add-habit form.
- **i18n**: every string in the prototype is looked up from a `{ en: {...}, fr: {...} }` table keyed by a `lang` state value, switchable live from Settings — no hardcoded copy. Only the "Shelf" brand name itself is left untranslated.
- **Theme switching**: accent theme and light/dark/system mode are both live-switchable from Settings and immediately repaint the whole app — there is no separate "restart to apply" step.

## State Management
State needed, mirroring the prototype's shape:
- `books`: list of catalogued books — `{ id, title, subtitle?, author, isbn, pages, published, genres: string[], addedAt, reading?: { status, page } }`. `reading` is populated/owned by Habits; Shelf reads it if present but never writes it.
- `queue`: in-progress batch-scan items — `{ qid, title, author, genre, status: 'ready'|'duplicate'|'needs-genre', isbn?, pages?, published?, suggestedGenre?, apiCategory? }`.
- Scan session state: `scanMode` (barcode/cover), `scannedCount`, hint-visibility timer.
- Draft state for the manual-entry form (title, subtitle, isbn, pages, datePublished, authors, genres) — separate from any saved book until "Save" is pressed.
- Global preferences: `lang` (en/fr), `themeMode` (light/dark/system), `accentTheme` (one of the 4 Habits theme keys). These should be persisted the same way Habits persists its own theme/appearance/language (see `DESIGN_SYSTEM_habits_reference.md` §7 — Notifier + immediate-persist setter + `readPersisted*` on startup).
- Real implementation should back `books` with whatever store Habits' own habit data uses (the reference doc implies Notion-backed reads/writes with local cache) — this was intentionally left as sample local state in the prototype.

## Design Tokens
See `DESIGN_SYSTEM_habits_reference.md` for the authoritative neutral/theme token values (§1) and spacing/radius constants (§3) — Shelf reuses them unchanged. This prototype's dark-mode neutral values (not present verbatim in the reference doc, which only specifies light-mode hex/oklch examples) were authored as:

| Token | Light | Dark |
|---|---|---|
| `bg` | `oklch(0.97 0.006 75)` | `oklch(0.19 0.008 75)` |
| `surface` | `oklch(0.995 0.002 75)` | `oklch(0.24 0.008 75)` |
| `text` | `oklch(0.22 0.01 60)` | `oklch(0.95 0.005 75)` |
| `muted` | `oklch(0.55 0.01 60)` | `oklch(0.65 0.01 75)` |
| `border` / `track` | `oklch(0.9 0.006 75)` | `oklch(0.32 0.01 75)` |
| `dark` | `oklch(0.32 0.01 60)` | `oklch(0.55 0.01 75)` (mid-grey, per the reference doc's "stays the odd one out in both directions" rule) |
| `alert` | `oklch(0.55 0.15 30)` | `oklch(0.68 0.15 30)` |

Accent/secondary values are copied verbatim from the reference doc's 4-theme table and stay fixed across light/dark; only their "soft" tint backgrounds get a separate light/dark pair (lighter tint on light bg, darkened tint on dark bg) since the reference doc doesn't spell out dark-mode soft values either.

**Genre cover colors** (Shelf-specific, new token use — not part of the Habits system): each genre gets a fixed hue at `oklch(0.5 0.1 <hue>)`, independent of accent theme or light/dark, so covers stay recognizable regardless of the user's theme choice:
Fiction 260 · Sci-Fi 195 · Fantasy 300 · Business 90 · Self-Help 20 · Non-Fiction 230 · Biography 350 · History 140.

Spacing/radius: card radius 18px, pill radius 20px, small-control radius 9px, screen horizontal padding 20px, card padding 14–16px, list gap 10px — all identical to the Habits reference doc's §3.

## Assets
No bitmap images. All icons (search, plus, checkmark, chevron) are simple hand-drawn inline SVGs, matching the Habits app's own icon convention (see reference doc §Assets). The empty-state illustration is a placeholder (diagonal-stripe pattern) — replace with a real illustration asset. Book covers are solid genre-colored blocks, not real cover art — replace with actual cover images/thumbnails when available (e.g. from the same book-metadata API used for scanning).

## Files
- `Shelf.dc.html` — prototype source (open directly in a browser). Includes a left-hand dev panel (screen jump list, "Load sample library"/"Reset demo" buttons) that is prototype-only scaffolding, not part of the design.
- `ios-frame.jsx` — cosmetic iPhone bezel used to preview the prototype; not part of the design.
- `DESIGN_SYSTEM_habits_reference.md` — the sister app's current design system doc (source of truth for tokens/components Shelf reuses).
- `screenshots/` — one PNG per screen/state, numbered in flow order:
  1. `01-empty-state.png` 2. `02-shelf-grid.png` 3. `03-scan-initial.png` 4. `04-scan-2-scanned.png`
  5. `05-queue-review.png` 6. `06-ocr-ranked-list.png` 7. `07-ocr-manual-search.png` 8. `08-dedupe-dialog.png`
  9. `09-genre-confirm.png` 10. `10-manual-entry.png` 11. `11-book-detail.png` 12–14. onboarding 1–3
  15. `15-settings.png`
