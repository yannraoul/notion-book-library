# NBLM-2 — Home screen (shelf grid + empty state), sample data

Built the shelf grid and its empty-state variant against a hardcoded
sample library — no Notion calls yet. Follows the same order the sister
Habits app used: a real screen against local/fake data first, to validate
the theme/typography/layout foundation before touching the network layer.
Source of truth for layout/copy was
`design/design_handoff_shelf/Shelf.dc.html` (GRID/EMPTY STATE sections)
and `design/design_handoff_shelf/README.md`; ARB copy already existed from
NBLM-1.

Also stood up the app's navigation shell for the first time — bottom-nav
(Home/Settings), hand-rolled per `instructions.md`'s no-`AppBar` convention,
`IndexedStack`-backed so tabs stay mounted — since Home needs somewhere to
live and every future screen will reuse this shell.

`ProviderScope` + a `colorTokensProvider` (same reusable shape as the
sister app's own provider — theme + platform `Brightness` in, tokens out)
are wired in `main.dart` for the first time this milestone; `AppTheme` is
hardcoded to `terracotta` until Settings gets a real switcher.

- IN: `Book`/`ReadingStatus` models (decoupled from Notion's property
  shape), `genre.dart` label helper, `booksProvider` seeded with 6 sample
  books mirroring the design prototype's own `SEED_BOOKS`, `RootShell` +
  `HomeScreen` + placeholder `SettingsScreen`, `ProviderScope` +
  `colorTokensProvider` wiring, one new ARB key (`comingSoon`) for the
  FAB/CTA stub actions.
- OUT: Notion connection, real persistence, scan/OCR/dedupe flows, book
  detail screen, genre-filter sheet interactivity (tabs render but only
  "All" is meaningful), theme/language switching UI (Settings is a
  placeholder) — all separate future milestones.
- Done: `flutter analyze` clean; built and ran on `-d windows`, visually
  confirmed against `design/design_handoff_shelf/screenshots/02-shelf-grid.png`
  — grid layout, genre tile colors (self-help/business/sci-fi), tabs row,
  FAB, and bottom nav all match; French locale renders correctly
  (Accueil/Réglages/Tout/Par genre/Récents).
- Open decisions: none new — carries forward NBLM-1's open items
  (genre-list reconciliation, French-default assumption) unchanged.
