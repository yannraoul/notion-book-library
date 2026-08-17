# NBLB-2 — iOS home screen showed "Notion Book Library" instead of "Shelf"

`ios/Runner/Info.plist`'s `CFBundleDisplayName` was still the literal
`flutter create` scaffold value from NBLM-1 (`Notion Book Library`) —
never updated to the product name `Shelf` used everywhere else (app copy,
`CFBundleName`... well, `CFBundleName` is `notion_book_library`, the
package identifier, which is correct as-is; it's `CFBundleDisplayName`
specifically that's user-facing, shown under the home screen icon).
Slipped through NBLM-1 unnoticed since Windows dev testing never surfaces
the iOS home screen — only spotted once Yann had a real IPA on his phone
via Codemagic/Sideloadly.

Fix: `CFBundleDisplayName` → `Shelf`.

Not locally verified — no Mac/iOS device testing available in this
environment (see `CLAUDE.md`'s Applied Learning notes); verification is
the next Codemagic → Sideloadly install.

Note: Android's `AndroidManifest.xml` has the equivalent
`android:label="notion_book_library"` (the raw package name, not a
display name) — left as-is since the sister Habits app has the identical
unfixed state (`android:label="notion_habit_tracker"`), and no Android
device is used for testing either project currently.
