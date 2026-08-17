# NBLB-7 — cover-mode UX: square guide didn't fit books, no OCR preview, "search manually" looked like an error, and OCR text could be stale

Four related complaints about the cover-photo flow after live iPhone
testing, all in `lib/screens/scan_screen.dart` and
`lib/screens/ocr_candidates_screen.dart`:

1. **Square framing guide.** The 220×220 guide box was shared between
   barcode and cover modes. A book cover is portrait, not square, so it
   was hard to center. Fixed: cover mode now uses a 190×270 portrait guide
   (barcode mode keeps the 220×220 square).
2. **"Search manually" read as an error message, not a button.** It was a
   bare `TextButton` styled in `tokens.alert` (the app's red/warning
   color) with no button chrome. Restyled as a full-width `OutlinedButton`
   matching the app's existing secondary-action pattern (see
   `dedupe_screen.dart`'s `addSeparate` button).
3. **No visibility into what OCR actually read.** `OcrCandidatesScreen`
   went straight from "photo taken" to a ranked (or silently empty)
   results list — the raw OCR text was only ever shown if you gave up and
   tapped through to Manual Search. Added a small read-only card at the
   top of the OCR screen showing the actual text that was read, plus an
   explicit "no matches found" message instead of a blank list when
   results come back empty.
4. **The actual data bug**: after a failed barcode attempt on the back
   cover, then switching to cover mode and photographing the front cover,
   the OCR search text contained content that looked like it came from the
   back cover (including barcode digits) rather than the front cover just
   photographed. `_captureCover` read `_lastCapture?.image` — whatever
   frame the barcode analyzer had most recently cached — which is throttled
   (`detectionTimeoutMs`, 250ms by default) and gated on the previous
   frame's processing finishing; a tap shortly after a mode switch could
   still pick up a frame from before the reframe.

   Fix: `_captureCover` no longer reads `_lastCapture` at all. It now
   registers a `Completer<BarcodeCapture>` before waiting, which
   `_onCapture` resolves with the *next* frame delivered after the tap —
   guaranteeing whatever gets OCR'd was captured strictly after the
   capture button was pressed, with a 3s timeout falling through to the
   existing capture-failed error path. Also added `debugPrint` logging of
   the raw OCR guess (length + content) so a future test can confirm
   whether this fully explains what was seen.

   Not fully certain this was the *only* contributing factor — the guide
   box is decorative only (no `scanWindow` is set on the controller), so
   the actual captured frame is the full camera view, not just what's
   inside the guide rectangle; if extra content from outside the intended
   frame is still picked up after this fix, cropping the captured image to
   the guide rectangle before OCR would be the next step, but that's a
   larger change (new image-processing dependency, `BoxFit.cover`
   geometry math) not attempted here.

New strings added to both `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`:
`ocrReadLabel`, `ocrNoMatches`. `flutter analyze` clean, existing unit
tests still pass. Not locally verified on-device — needs the next
Codemagic → Sideloadly → iPhone run, same as the other camera-pipeline
fixes this session.
