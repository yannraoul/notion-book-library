# NBLB-9 — cover-photo capture regressed to always failing (regression from NBLB-8)

After NBLB-8 shipped (added `scanWindow`, a torch toggle, and restricted
the shared `MobileScannerController` to `formats: [BarcodeFormat.ean13]`),
cover-photo capture started failing outright — "Couldn't capture the
cover photo — try again" every time, where it had previously at least
produced a photo (even if NBLB-7's OCR-text-quality issue was still
separately unresolved).

Root cause isn't confirmed (no device logs available in this
environment — see `CLAUDE.md`), but the timing lines up with exactly one
plausible mechanism: barcode mode and cover mode share the *same*
`MobileScannerController` (a hard constraint since NBLB-6 — the native
camera session is a process-wide singleton, confirmed by reading the
`mobile_scanner` source). The `formats: [BarcodeFormat.ean13]` restriction
added in NBLB-8 applies to that shared controller unconditionally, even
though cover mode never reads `capture.barcodes` at all — it only needs
`capture.image`, delivered via the same analyzed-frame pipeline that
`formats` also governs. If restricting formats changes how/whether the
native side processes and returns frames (plausible, unconfirmed), that
would explain cover mode's capture-wait (`_captureCover`'s
`Completer<BarcodeCapture>`, added in NBLB-7) timing out where it
previously didn't.

Fix: reverted the `formats` restriction — back to `mobile_scanner`'s
default (detect all formats). It was already flagged in NBLB-8 as "not
expected to be a real fix on its own" for barcode detection, so there's
little to lose and a plausible active regression to gain back. Also:

- Bumped the cover-capture wait timeout from 3s to 5s (a little more
  slack, in case frame delivery is genuinely just slower than expected
  rather than fully stalled).
- `scanCoverCaptureFailed` now shows the actual caught exception in the
  SnackBar text (`Text('$e')`, same pattern already used by
  `manualEntryError`/`homeLoadError` elsewhere in this app) instead of a
  generic message. There's no practical way to pull real device logs in
  this environment (no Mac, no `idevicesyslog` equivalent) — surfacing
  the real error directly in the UI is the only diagnostic path available
  if this fix doesn't fully resolve it.

Separately: barcode detection on the Kosigan books remains unresolved and
is **not** treated as caused by this same regression — it was already
failing before NBLB-8 shipped (torch didn't fix it either, per live
testing), consistent with the working theory that it's a hard-to-scan
physical print rather than an app bug (3+ other books scan fine). Not
touched further here; manual search/entry remains the practical path for
those two specific books.

Not locally verified — needs the next Codemagic → Sideloadly → iPhone run.
