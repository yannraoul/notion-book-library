# NBLM-5 — Settings preferences (theme + language)

Filled in Settings' "Preferences" section: the 4 shared accent themes and
French/English language, both live-switchable and persisted across
restarts. Notion connection (NBLM-3) stays untouched. Design's separate
Appearance (light/dark override) and About sections are still out of
scope — Shelf already auto-follows the OS light/dark setting via
`MediaQuery.platformBrightnessOf` rather than offering a manual override,
so there was no override control to build, and About stays behind the
trailing "coming soon" note.

Implementation is a direct port of the sister Habits app's actual
settings-persistence pattern (read its code, not just
`instructions.md`'s summary of it): enum → `Notifier` whose setter writes
state then immediately persists via a generic key/value `SettingsStorage`
→ a `readPersisted*()` function called before `runApp` to override the
provider's initial value, so there's no flash of the default before the
saved choice loads. `_ThemeSelector`/`_LanguageToggle`/`_ThemeOption`/
`_ThemeSwatchDot`/`_SegmentedOption` widgets are also ported directly from
the sister app's `settings_screen.dart`.

- IN: `AppDatabase` bumped to schema v2 (adds a `settings` table),
  `SettingsStorage` (generic key/value, decoupled from the `AppTheme`/
  `AppLanguage` enums to avoid a circular import), `theme_provider.dart`'s
  `_appThemeProvider` replaced with a real persisted `AppThemeNotifier`/
  `appThemeProvider`, new `locale_provider.dart` (`AppLanguage`,
  `AppLanguageNotifier`, `appLanguageProvider`, `appLocaleProvider`),
  `main.dart` now `async` and loads both persisted values before `runApp`
  via `ProviderScope` overrides, Settings' Preferences section (theme
  swatches + language segmented control).
- OUT: Appearance (light/dark manual override — not needed, system
  brightness already auto-applies), About Shelf section, per-theme iOS
  home-screen icon switching (the sister app has this via `app_icon.dart`;
  Shelf's scaffold only has one default `AppIcon` set, no theme-variant
  icon assets exist to switch to).
- Done: `flutter analyze` clean. Live-tested on `-d windows`: switching
  theme and language both apply instantly across the whole app (Home grid,
  Notion connection card, bottom nav, Settings itself); fully closing and
  relaunching confirms both choices persisted with no flash of the
  terracotta/French default before the saved values load.
- Open decisions: none new.
