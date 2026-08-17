# NBLB-3 — iOS scan pipeline: barcode never detected, cover capture silently fails

Live iPhone testing (via Codemagic → Sideloadly, camera permission already
granted) surfaced two symptoms in `lib/screens/scan_screen.dart`: barcode
mode never detects a scan, and cover-photo capture doesn't seem to produce
a result. Checked the barcode against a reference photo of the physical
book (`9782073060327`, a Gallimard "Folio SF" title) — a clean, standard
EAN-13 with intact quiet zones, ruling out a malformed barcode.

Traced the installed `mobile_scanner` 7.4.0 package (Dart and iOS Swift
plugin source) and found the screen had **zero error handling and zero
logging** anywhere in the scan flow:

- `MobileScanner(controller: _controller)` had no `errorBuilder` — a
  camera-init failure (permission edge case, camera already in use, etc.)
  fell back to the package's generic default error widget, with nothing
  logged.
- The barcode stream subscription (`_controller.barcodes.listen(_onCapture)`)
  had no `onError` — a stream-level failure was silently dropped.
- `_captureCover`'s `try { ... } catch (_) {}` swallowed *any* exception
  (temp-file I/O, ML Kit OCR failure, anything) with no logging and no user
  feedback — the capture button spinner just stopped with nothing
  happening, matching the reported symptom exactly. The same function also
  returned silently when OCR found no text at all.

Root cause for the barcode non-detection is most likely the single
`MobileScannerController(returnImage: true)` shared across both modes:
every analyzed frame paid the cost of JPEG-encoding the frame
(`currentImage.jpegData(...)` on iOS) even in barcode mode, which never
needs the image. `returnImage`'s performance cost is a documented issue in
mobile_scanner's own changelog. `returnImage` is a constructor-only field
— it can't be toggled at runtime — so the fix splits the controller by
mode instead of sharing one.

Fix, all in `lib/screens/scan_screen.dart`:

- Two `MobileScannerController`s — `returnImage: false` for barcode mode,
  `returnImage: true` only for cover mode — with only one `MobileScanner`
  widget (keyed by mode) ever mounted at a time, so switching modes
  auto-starts/auto-stops the right controller via the package's own widget
  lifecycle.
- `errorBuilder` on the `MobileScanner` widget logs the
  `MobileScannerException` (via `debugPrint`) and shows the error message
  inline instead of a silent generic fallback.
- `onError` added to both barcode-stream subscriptions, logged via
  `debugPrint`.
- `_captureCover`'s catch block now logs the exception and shows a
  `SnackBar` (`scanCoverCaptureFailed`) instead of swallowing it silently;
  an empty OCR result now shows a `SnackBar` too (`scanCoverNoText`)
  instead of returning with no feedback.

New strings added to both `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb`:
`scanCameraError`, `scanCoverCaptureFailed`, `scanCoverNoText`.

Not locally verified — no Mac/camera pipeline available in this
environment (see `CLAUDE.md`'s Applied Learning notes; camera features
can't be exercised on `flutter run -d windows` either). The controller
split is a well-justified fix, backed by mobile_scanner's own documented
`returnImage` performance caveat, but it's a best effort rather than a
confirmed fix — if detection still fails after this, the new
logging/SnackBars should now surface the actual error on the next
Codemagic → Sideloadly → iPhone run instead of dead silence.
