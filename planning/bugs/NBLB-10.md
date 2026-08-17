# NBLB-10 — cover capture still hangs then fails; added direct search as a fallback entry point

NBLB-9's `formats` revert didn't fix cover-photo capture — still fails,
and Yann reported a new detail: the shutter button's loading spinner sits
for a while before the "couldn't capture" error appears. That's
consistent with `_captureCover`'s `Completer<BarcodeCapture>` wait
(NBLB-7) genuinely hitting its timeout rather than failing instantly —
meaning no frame is being delivered via `_controller.barcodes` at all
while in cover mode, for the whole timeout window.

Combined with barcode mode also never detecting anything in the same
session (a separate, accepted physical-barcode issue — see NBLB-3/6/8,
not touched further here), the working theory is now: `mobile_scanner`'s
native frame-analysis loop can get stuck — stop delivering *any* further
frames — after enough failed barcode-detection attempts, and that stuck
state carries over when switching to cover mode within the same screen
session (both modes share one controller, a hard constraint since NBLB-6).
This is native-plugin internal state, not something diagnosable further
from Dart alone in this environment (no device logs available).

Fix, in `lib/screens/scan_screen.dart`: `_setMode` now restarts the
camera (`_controller.stop()` then `.start()`) whenever switching *into*
cover mode, forcing a clean analyzer state before the user gets a chance
to tap capture — rather than reactively discovering the analyzer is stuck
only after a 5-second wait. Not restarting on every entry into barcode
mode too, since there's no evidence that direction needs it and doing so
on every toggle would add unnecessary latency to normal scanning.

Separately, since this leaves cover-photo OCR as an unreliable path to
book search, added a third option to the Home screen's "+" add-book menu
(`lib/screens/home_screen.dart`): "Search for a book", going straight to
the existing `ManualSearchScreen()` (previously only reachable via the
OCR-candidates screen's "None of these" fallback) — a working, camera-free
way to find a book by typed title/author/subtitle whenever scanning isn't
cooperating. New l10n key `addSheetSearch` in both `app_en.arb`/
`app_fr.arb`.

`flutter analyze` and `flutter test` clean. Not locally verified — needs
the next Codemagic → Sideloadly → iPhone run for the camera-restart fix;
the new menu option needs no camera and was sanity-checked via
`flutter run -d windows` (code-review-level confidence only this round —
cut a visual screenshot pass short after it incidentally captured
unrelated windows on the desktop, deleted immediately, not investigated
further).
