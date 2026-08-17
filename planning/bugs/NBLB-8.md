# NBLB-8 — barcode-mode tuning: scanWindow, EAN-13-only formats, torch toggle

Evaluated a third external review claiming Apple Vision fails on the Folio
SF barcode due to "trailing alphanumeric margins forcing detection models
to expand their reading boxes" and recommending format restriction,
`scanWindow`, and torch. Most of the causal claims didn't hold up (see
conversation) — `detectionSpeed: DetectionSpeed.normal` and
`autoStart: true` are already `mobile_scanner`'s defaults (no-ops), and
"restricting formats improves raw line-pattern sensitivity" isn't how
Vision's detector actually works (confirmed by reading the plugin source
in NBLB-3's investigation — no per-symbology noise handling to unlock).
But two parts were genuinely worth doing independent of whether they
"fix" this specific barcode:

- `scanWindow` is a real, documented `mobile_scanner` feature that
  restricts native pixel analysis to a sub-rect of the frame — previously
  the barcode-mode guide box (`lib/screens/scan_screen.dart`) was purely
  decorative (no `scanWindow` was ever set, confirmed during NBLB-7).
  Wired a real `Rect.fromCenter` scanWindow matching the 220×220 guide via
  a `LayoutBuilder`, active only in barcode mode (cover mode still needs
  the full frame for OCR, not a narrow window).
- No torch/flash toggle existed anywhere in the UI. Added one
  (`_controller.toggleTorch()`, reactive via `ValueListenableBuilder` on
  the controller's own `torchState`) — legitimate low-light aid regardless
  of this specific barcode's outcome.

Also restricted `MobileScannerController(formats: [BarcodeFormat.ean13])`
since that's the only symbology a ISBN barcode ever uses (matches our own
`raw.startsWith('978'|'979') && length == 13` filter already in
`_onCapture`) — a minor decode-efficiency tidy-up, not expected to be a
real fix on its own.

**Context that shaped this**: by this point barcode scanning had been
confirmed working on 3 other books (Dungeon Crawler Carl ×2, Neuromancer)
and failing specifically on 2 French Gallimard Folio SF titles (Le Bâtard
de Kosigan II and III) — strong evidence this is a hard-to-scan print
series (small trade paperback, cream paper, possibly print/lighting
conditions) rather than an app bug. These tuning changes are worth having
regardless, but manual entry/search remains the practical path for these
specific two books.

`flutter analyze` clean, existing unit tests still pass. Not locally
verified on-device — needs the next Codemagic → Sideloadly → iPhone run.
