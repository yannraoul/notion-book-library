# NBLM-11 — Onboarding carousel + About Shelf section

## Why

Settings' bottom section just showed "Not built yet" — a stand-in for
the design prototype's "About Shelf" block. Investigating what would fill
it in surfaced that onboarding itself didn't exist at all either: the
`ob1Title`/`ob2Title`/`ob3Title`/`onboardingSkip`/`obScanCta`/etc. l10n
strings existed (leftover from the design handoff) but nothing in `lib/`
referenced them, no screen file, no first-launch trigger. Scoped this as
its own milestone rather than folding it into a quick About-section patch
since it's real new surface area: a 3-page carousel, a first-launch app
route, and the About section's "View onboarding again" link all had to be
built together for either half to make sense.

## What changed

- **`lib/screens/onboarding_screen.dart`** (new) — 3-page carousel,
  button-driven (no swipe), matching `Shelf.dc.html`'s exact structure
  (lines 350-394: icon/title/body or icon-rows, a 3-dot progress
  indicator, Skip link on pages 1-2, Next button, page 3's two stacked
  buttons). Illustration SVGs from the prototype were substituted with
  equivalent Material icons (`menu_book_outlined`, `qr_code_scanner`,
  `photo_camera_outlined`, `edit_outlined`, `check_circle`) rather than
  hand-traced — layout, spacing, color, and button/copy behavior all
  follow the prototype exactly, only the decorative icons are a
  substitution.
- `OnboardingScreen(standalone: bool)` — `true` (default) when it's the
  app's root on first launch, so finishing/skipping replaces the whole
  navigation stack with `RootShell` (and, from the "Scan your first book"
  exit, pushes `ScanScreen` on top of that); `false` when pushed from
  Settings as a replay, so exiting just pops back to Settings instead.
  Both paths persist a `hasSeenOnboardingKey` flag via the existing
  `SettingsStorage` (the same generic key/value `settings` table already
  used for theme/language — no schema change needed).
- **`lib/main.dart`**: reads that flag alongside the existing persisted
  theme/language reads at startup and picks `OnboardingScreen()` vs.
  `RootShell()` as `MaterialApp.home` accordingly — this is genuinely the
  first time the app has had any first-launch-specific routing.
- **`lib/screens/settings_screen.dart`**: the "Not built yet" `Text` is
  now a real "About Shelf" section — `settingsAboutBody`'s existing
  string (already accurately describing the Shelf/Habits field-ownership
  split) plus a "View onboarding again" link pushing
  `OnboardingScreen(standalone: false)`.
- Removed the now-fully-unused `comingSoon` l10n key (it had exactly one
  call site, which this replaces) from both ARB files.
- Deleted `test/widget_test.dart` — discovered while fixing a build error
  from this change (it still called `MyApp()` without the new required
  `showOnboarding` param). It was unrelated `flutter create` boilerplate
  testing a counter UI that was replaced back in NBLM-1/2, already
  failing before this change (confirmed by stashing and re-running it
  earlier this session) — patching its constructor call would have kept
  a test that still asserts on a UI that doesn't exist, so removed it
  instead of patching around it.

## Verification

`flutter analyze` and `flutter test` both clean. Attempted a
`flutter run -d windows` visual pass but abandoned it after window-capture
targeting in this environment proved unreliable (two attempts each
grabbed an unrelated window instead of the app — one incidentally
captured sensitive unrelated content on the desktop, immediately deleted
without further action). Relying on code-review-level confidence instead:
the implementation closely mirrors both the design prototype's exact
onboarding markup (line-by-line cross-referenced) and this codebase's
established `ConsumerStatefulWidget`/`SettingsStorage`/button-styling
conventions used throughout every other screen. Worth an explicit
first-launch check (fresh install or clear app data) on the next real
device or `flutter run -d windows` session with reliable window capture.
