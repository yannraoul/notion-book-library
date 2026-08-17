# Changelog: bug fixes outside the milestone cycle

Small fixes discovered outside of a milestone's own development/testing
cycle live here, each with an **NBLB-y** (Notion Book Library Bug)
identifier — as opposed to `ROADMAP.md`'s **NBLM-x** (Notion Book Library
Milestone) entries, which are for new features/scope. A bug found and fixed
*while a milestone is still in progress* stays folded into that milestone's
own `features/NBLM-x.md` entry instead of getting an NBLB id here — this
file is only for bugs that surface after the milestone that introduced them
has already shipped. See `../instructions.md` for the full logging
convention (commit message pattern, when something is NBLM vs NBLB, etc).
Full detail for each bug lives in its own `bugs/NBLB-y.md` file; this file
is just the index.

## Bugs

- [NBLB-1](bugs/NBLB-1.md) — iOS CocoaPods build failure (deployment target too low for google_mlkit_commons)
- [NBLB-2](bugs/NBLB-2.md) — iOS home screen showed "Notion Book Library" instead of "Shelf"
- [NBLB-3](bugs/NBLB-3.md) — iOS scan pipeline: barcode never detected, cover capture silently fails
- [NBLB-4](bugs/NBLB-4.md) — search confidence ranked author-name-in-title above the real title
- [NBLB-5](bugs/NBLB-5.md) — bottom nav bar didn't extend to the bottom of the screen like the Habits app
- [NBLB-6](bugs/NBLB-6.md) — cover mode threw "MobileScannerController is already running" (regression from NBLB-3)
- [NBLB-7](bugs/NBLB-7.md) — cover-mode UX: square guide, no OCR preview, "search manually" looked like an error, stale OCR text
- [NBLB-8](bugs/NBLB-8.md) — barcode-mode tuning: scanWindow, EAN-13-only formats, torch toggle
- [NBLB-9](bugs/NBLB-9.md) — cover-photo capture regressed to always failing (regression from NBLB-8)
