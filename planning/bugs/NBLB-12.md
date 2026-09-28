# NBLB-12 — cover capture always timed out (root cause); barcode scanWindow likely blocking detection

**Root cause of NBLB-3/7/9/10** (cover capture timing out with
`TimeoutException after 0:00:05`): on iOS, `mobile_scanner`'s
`captureOutput` returns early when Vision finds no barcode
(`if results.isEmpty { return }`), so no event — and no image — ever
reaches Dart for a frame without a barcode. Cover mode waited for such a
frame, so pointing at a front cover always timed out. The earlier "fires on
every analyzed frame" note was true for Android only.

Fix (`lib/screens/scan_screen.dart`): cover mode now stops the scanner,
opens the native camera via `image_picker` (new dependency), runs OCR on the
returned file, and restarts the scanner. Removed the fresh-frame completer,
the mode-switch camera restart (NBLB-10 workaround for the wrong theory) and
`returnImage`.

Barcode mode: removed the 220pt `scanWindow` added in NBLB-8. Vision's
`regionOfInterest` requires the whole barcode inside the window, which is the
likely reason previously-scannable barcodes stopped being detected. The guide
box is now cosmetic. Not device-verified — needs the next Codemagic →
SideStore run.
