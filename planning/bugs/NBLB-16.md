# NBLB-16 — scan-status chip promoted from debug scaffolding to a real feature

Both books Yann couldn't add now work with the Google Books key in place
(NBLM-16) — the barcode/lookup chain in `lib/screens/scan_screen.dart` is
confirmed working end to end. Only remaining feedback: he likes the
"Detections: xx • last: ..." readout added in NBLB-13 as a diagnostic, but
wants it looking like an intentional feature, not leftover debug text.

Changes, all in `lib/screens/scan_screen.dart`:

- New `_DetectionChip` — a pill matching the app's existing chip style
  (same family as the header's scanned-count pill), two lines: a small
  muted "N detected" label, then the format + raw value in a slightly
  larger weight with tabular-figure digits so the ISBN reads cleanly.
  Replaces the plain `Container` + single-line `Text` from NBLB-13.
- The chip now *replaces* the generic `scanHint` ("No barcode found — try
  Cover photo above") once anything's been detected, instead of both
  competing for the same bottom-of-viewfinder space — the hint only ever
  made sense pre-detection anyway.
- Split the old single pre-formatted debug string
  (`'${format} "${raw}" (len ${length})'`) into separate `_lastFormat`/
  `_lastRawValue` fields, dropping the `(len N)` suffix — that was only
  useful for diagnosing malformed reads during the NBLB-13 investigation,
  not meaningful now that detection is confirmed working.
- New l10n key `scanDetectionCount` (en/fr) replaces the old
  `scanDebugInfo` (removed).

Re-framed the doc comments accordingly — no longer "temporary, remove once
confirmed working," since Yann wants to keep it.

`flutter analyze`/`flutter test` clean. Layout not yet device-verified —
next Codemagic → SideStore run.
