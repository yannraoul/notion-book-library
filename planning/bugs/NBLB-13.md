# NBLB-13 — NBLB-12/NBLM-15 didn't hold up on device: barcode still undetected, cover UX doubled up, rating still hidden

Device testing on the Codemagic build from `d94e99e` (NBLB-12 + NBLM-15)
found all three still broken:

**Barcode still not detected**, even on a barcode (the William Gibson
trilogy) that scanned correctly before. NBLB-12's `scanWindow` removal
didn't fix it, and since `debugPrint` output isn't visible on a sideloaded
build without a Mac console, we've had no real signal on whether Vision is
detecting nothing at all or detecting something the ISBN filter then
rejects — every fix in this area (NBLB-3/6/8/9/12) has been a best-effort
guess with no device feedback loop. Rather than guess again,
`lib/screens/scan_screen.dart` now mirrors the existing raw-detection log
on-screen (`_detectionCount`/`_lastDetectionDebug`, shown as small text
under the barcode guide box) — the next device run will show whether *any*
detection event ever fires, and if so, what format/value/length Vision
actually reports, instead of another blind theory. Meant to come out once
detection is confirmed working again.

**Cover-photo UX**: NBLB-12 fixed the timeout but left a bad interaction —
tapping the shutter opened iOS's real camera *on top of* Shelf's own live
camera preview, which reads as two stacked cameras. `MobileScanner` can't
simply be unmounted for cover mode to hide it: it only calls
`controller.start()`/`.stop()` tied to its own mount lifecycle when it
doesn't own the controller check turned out to run regardless of
ownership, and mounting/unmounting it while switching modes re-triggers
that start/stop cycle on the same controller — exactly the kind of race
NBLB-6 already hit once. Fix: `MobileScanner` stays continuously mounted
in both modes; cover mode now draws an opaque static prompt over it
(`scanCoverPrompt` — icon + instructions) instead of unmounting it, so the
live feed is never visible in cover mode at all, only the "tap to open
your camera" prompt, then the one real camera.

**Rating still not showing**: `Status` is confirmed to be Notion's
dedicated `status` property type (see `BookStatus`'s doc comment), but
`Rating`'s type was never actually confirmed — the original "`select`
whose option name is a run of star emoji" parsing was an assumption, never
device-verified, and is the likely reason the new detail-page row NBLM-15
added still renders nothing. `NotionApi._parseRating` now reads whichever
of `select`, `number`, `formula`, or `rollup` the property actually is,
instead of assuming `select`.

All three remain unverified until the next Codemagic → SideStore →
iPhone run — `flutter analyze`/`flutter test` clean, no device access in
this environment (see `CLAUDE.md`).
