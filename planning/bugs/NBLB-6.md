# NBLB-6 — cover mode threw "MobileScannerController is already running" (regression from NBLB-3)

NBLB-3's fix split the scan screen's single `MobileScannerController` into
two (`returnImage: false` for barcode mode, `returnImage: true` for cover
mode) to avoid the JPEG-encoding cost on every barcode-mode frame. On a
real iPhone, switching to cover mode threw: "Camera error: The
MobileScannerController is already running. Stop it before starting
again." — and barcode detection was still not working either, disproving
the `returnImage` cost as the cause of that separate problem.

Root cause of the new crash: read `mobile_scanner` 7.4.0's controller
source more carefully this time and found
`static MobileScannerController? _platformSessionOwner` — the native
camera session is a **process-wide singleton** tracked by a static field,
not something each `MobileScannerController` instance owns independently.
Switching modes unmounted the old `MobileScanner` widget (which calls
`controller.stop()`, asynchronously) while mounting the new one (which
calls `controller.start()`) in the same rebuild pass — there's no
guarantee the old controller's native-side session release completes
before the new controller's start reaches native code, so the platform
layer sometimes still saw the session as held and rejected the second
`start()`.

Fix: reverted to a single shared `MobileScannerController(returnImage:
true)` for both modes in `lib/screens/scan_screen.dart` (the original
NBLM-7 design) — this is what the package is actually built around, and
splitting controllers isn't a safe way to avoid the `returnImage` cost
given the singleton session model. Kept NBLB-3's other improvements
(`errorBuilder`, `onError` on the barcode stream, `_captureCover`'s
error/empty-result `SnackBar`s), and added logging of *every* raw barcode
detection (format + value), not just ones that pass the ISBN filter — so a
future device run can tell us whether the camera is detecting nothing at
all, or detecting something the filter rejects.

Not locally verified — needs the next Codemagic → Sideloadly → iPhone run,
same as NBLB-3/NBLB-5.
