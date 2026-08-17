import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_icon.dart';
import '../services/settings_storage.dart';
import '../theme/color_tokens.dart';

const _themeStorageKey = 'theme';

/// Persists via [SettingsStorage] — [setTheme] writes through on every
/// change; `build()` just returns whatever initial value the app was
/// constructed with (see `main.dart`, which loads the saved value before
/// `runApp` and overrides this provider's factory with it).
class AppThemeNotifier extends Notifier<AppTheme> {
  final AppTheme _initial;
  final SettingsStorage _storage;

  AppThemeNotifier(this._initial, {SettingsStorage? storage}) : _storage = storage ?? SettingsStorage();

  @override
  AppTheme build() => _initial;

  Future<void> setTheme(AppTheme theme) async {
    state = theme;
    await _storage.write(_themeStorageKey, theme.name);
    await setAppIcon(theme);
  }
}

/// Reads back a previously persisted theme, or `null` if none is stored
/// (or the stored value doesn't match a known [AppTheme]).
Future<AppTheme?> readPersistedTheme(SettingsStorage storage) async {
  final raw = await storage.read(_themeStorageKey);
  if (raw == null) return null;
  for (final theme in AppTheme.values) {
    if (theme.name == raw) return theme;
  }
  return null;
}

final appThemeProvider = NotifierProvider<AppThemeNotifier, AppTheme>(
  () => AppThemeNotifier(AppTheme.terracotta),
);

/// Same reusable shape as the sister Habits app's own `colorTokensProvider`:
/// derives tokens from the selected theme and the current platform
/// brightness. `brightness` is passed in by the caller (from
/// `MediaQuery.platformBrightnessOf(context)`) rather than read here, since
/// providers shouldn't depend on `BuildContext` — Shelf follows the OS
/// light/dark setting automatically rather than offering a manual override.
final colorTokensProvider = Provider.family<AppColorTokens, Brightness>((ref, brightness) {
  final theme = ref.watch(appThemeProvider);
  return AppColorTokens.forTheme(theme, brightness: brightness);
});
