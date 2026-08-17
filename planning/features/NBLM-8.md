# NBLM-8 — Multi-theme app icon (light/dark)

Shelf shipped with Flutter's default scaffold icon until now. This gives
it a real one, matching Habits' capability: a different home-screen icon
per accent theme (4), each with a light and dark variant, switching live
as the in-app theme changes — no third-party plugin, hand-rolled the same
way Habits did.

Went straight to the format that actually works on-device, skipping two
rounds of trial and error Habits went through first (researched via its
NHTM-8/10/11 commit history before starting):
- Its first icon set used the legacy per-size/per-idiom `.appiconset`
  format; iOS 26 "Liquid Glass" misapplied a blur to it because the PNGs
  had no DPI tag (read as low-DPI flat art). Fixed by exporting at
  `dpi=(400,400)` — done here from the start.
- Even after that, dark-mode never actually applied on-device with the
  legacy format's per-image `"appearances"` tagging. The fix that finally
  worked: Xcode 16's "universal" format — exactly 2 PNGs per set (a
  1024×1024 light + a 1024×1024 tagged
  `"appearances": [{"appearance": "luminosity", "value": "dark"}]`),
  letting iOS synthesize every on-screen size itself. Used here from the
  start, so Shelf's icon sets never went through the broken legacy format
  at all.

Concept picked from 4 mocked directions (published as an artifact,
`shelf-icon-concepts.html` in this session's scratchpad, not committed),
then refined through several more rounds against two references Yann
liked (a flaticon bookshelf icon and an Adobe Stock line icon): **"Books
on a shelf"** — a shelf baseline with 5 spines, touching edge-to-edge
(no gaps), one leaning against the last upright book, a thin inset label
stripe on each spine for a small, deliberate amount of detail. Only 3
colors throughout (accent/secondary/neutral) so it carries over exactly
to all 4 accent themes.

The leaning book took the most iteration — worth recording since the
final approach is reusable: PIL's `Image.rotate(angle, center=pivot,
expand=False)` rotates a whole canvas around a fixed pivot point that
stays at the same pixel location in the output regardless of angle, so
drawing the book with its bottom-left corner *at* the pivot and pasting
that canvas so the pivot lands on the shelf line guarantees the book's
foot is exactly planted, for any angle — no more hand-tuning paste
offsets per angle. Getting it to rest against the correct neighbor
(rather than crossing over it) needed measuring the rotated shape's
actual pixel bounding box (`Image.getbbox()` on an isolated RGBA render)
rather than eyeballing the position, then solving for the exact anchor
x that puts its leftmost point on the neighboring book's rightmost edge.

- IN: `lib/services/app_icon.dart` (`setAppIcon(AppTheme)`, iOS-only,
  no-ops elsewhere, swallows `PlatformException` — cosmetic only),
  wired into `AppThemeNotifier.setTheme`
  (`lib/providers/theme_provider.dart`) right after persisting, same hook
  point as Habits. `ios/Runner/AppDelegate.swift` gets a
  `notion_book_library/app_icon` `FlutterMethodChannel` calling
  `UIApplication.setAlternateIconName` — copied from Habits'
  `AppDelegate.swift` line-for-line except the channel name, since I
  can't compile/verify Swift in this environment and Habits' version is
  the one already proven to work on-device. `ios/Runner/Assets.xcassets/`
  now has 4 `.appiconset` sets (`AppIcon` = primary/terracotta,
  `AppIcon-VertRouge`, `AppIcon-AmbreArdoise`, `AppIcon-SarcelleRouille`),
  each in the universal 2-file format. `project.pbxproj` gets
  `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` alongside the existing
  `ASSETCATALOG_COMPILER_APPICON_NAME` in all 3 build configs. No manual
  `CFBundleIcons` in `Info.plist` — Xcode generates it from the build
  setting (Habits found mixing the two approaches breaks
  `supportsAlternateIcons`). Android's 5 `mipmap-*/ic_launcher.png` files
  replaced with the static terracotta/light icon (no per-theme switching
  on Android — matches Habits' scope, and this project doesn't test on
  Android either).
- Art generation: an uncommitted Python/Pillow script
  (`gen_shelf_icons_final.py`, run from the scratchpad) drawing the
  shelf/books shape at 1024×1024 for all 4 themes × light/dark, using hex
  colors computed directly from `lib/theme/oklch.dart`'s conversion
  formula (accent/secondary constant across light/dark per theme;
  background/neutral swap per brightness, matching
  `AppColorTokens.forTheme` exactly) — same "build-time art tool, not app
  code" precedent as Habits, not committed to the repo.
- OUT: per-theme Android icon switching. A tinted/monochrome iOS variant
  (only light/dark `luminosity` appearances used, no `tinted`).
- Done: `flutter analyze` clean, `flutter build windows --debug`
  succeeds, live-tested theme switching still works with the new
  `setAppIcon` call in the hot path (no-ops correctly off-iOS, no crash).
  **Not yet verified on-device** — same caveat Habits itself still has
  open per its own NHTM-11 write-up: real confirmation that the icon
  switches per-theme and respects the phone's light/dark setting needs
  the next Codemagic → Sideloadly → iPhone cycle.
- Open decisions: none new.
