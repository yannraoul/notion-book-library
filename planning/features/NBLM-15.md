# NBLM-15 — Show reading rating on book detail

The `Rating` set in Habits after finishing a book is now shown read-only on
the detail screen's reading-status card as 1-5 stars (hidden when unrated).
`NotionApi` parses `Rating` tolerantly (counts ⭐, or falls back to a digit).
New l10n key `ratingLabel` (en/fr). Shelf still never writes `Rating`.
