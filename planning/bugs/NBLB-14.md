# NBLB-14 — cover capture: true in-app camera (not iOS's Camera app); rating star character was wrong

Follow-up to NBLB-13, from Yann's review of that plan before the next
device build.

**Cover photo, take two.** Yann asked why cover mode couldn't just reuse
the same in-app camera pointed at by barcode mode, instead of handing off
to iOS's Camera app. Checked `mobile_scanner`'s public API
(`MobileScannerController`) for any way to grab a still frame outside the
barcode-detection event — there isn't one; `analyzeImage()` goes the other
direction (accepts a file path, doesn't produce one), and the plugin's iOS
`captureOutput` only ever surfaces a frame to Dart when Vision finds a
barcode in it, which a bare cover deliberately has none of. So the live
feed genuinely can't be reused as-is for a barcode-free photo.

What's now in `lib/screens/scan_screen.dart`: cover mode runs its own,
separate `camera` package (`CameraController`) session for a real in-app
live preview, guide box and shutter — the same visual design as before,
just backed by a second, independent camera session instead of a
round-trip through iOS's Camera app. Only one of the two sessions
(`mobile_scanner`'s or `camera`'s) is ever live at a time: switching modes
awaits stopping one before starting the other, to avoid the native
"already running" race NBLB-6 hit. New `camera` dependency,
`image_picker` dropped (no longer used anywhere).

The barcode diagnostics text added in NBLB-13 is now also a slightly more
visible pill (background chip) rather than faint gray text, since it's
easy to miss otherwise.

**Rating.** Yann checked the actual Notion database directly: `Rating` is
a `select` with 5 options, each option's name a run of 1-5 **"★"**
characters — U+2605 BLACK STAR. NBLB-13's parsing counted "⭐" (U+2B50
WHITE MEDIUM STAR, a different Unicode character that merely looks
similar), which is the actual reason it never counted anything and the
row never rendered — not an unconfirmed-schema problem as NBLB-13
guessed. Fixed in `NotionApi._parseRating`/`_parseRatingText` to count
★ (and ⭐, defensively). Kept the `number`/`formula`/`rollup` fallbacks
from NBLB-13 since they're free and harmless.

**Barcode.** No code change this round beyond the diagnostics-panel
visibility bump above — Yann's own recollection is that scanning last
worked before the wishlist feature (NBLM-14) shipped. Checked that
commit's diff: NBLM-14 touched `book.dart`, `books_repository.dart`,
`notion_api.dart`'s *write* path, `manual_entry_screen.dart`,
`queue_screen.dart`, `book_detail_screen.dart`, and
`scan_queue_provider.dart`'s `commitReady` — nothing in
`scan_screen.dart` or the barcode-detection path itself. So NBLM-14
isn't the direct cause; the more likely candidate given the file history
is NBLB-8's `scanWindow` restriction (already reverted in NBLB-12), and
the timing is probably coincidental with when scanning was next
seriously exercised. Still waiting on the on-screen diagnostics from
NBLB-13 to confirm what's actually happening before making another
change here.

`flutter analyze`/`flutter test` clean. None of this is verifiable
without a device — next Codemagic → SideStore → iPhone run needed for
all three (see `CLAUDE.md`).
