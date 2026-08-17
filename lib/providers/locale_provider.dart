import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_storage.dart';

/// The 2 supported UI languages.
enum AppLanguage { fr, en }

const _languageStorageKey = 'language';

/// Persists via [SettingsStorage] — [setLanguage] writes through on every
/// change; `build()` just returns whatever initial value the app was
/// constructed with (see `main.dart`, which loads the saved value before
/// `runApp` and overrides this provider's factory with it).
class AppLanguageNotifier extends Notifier<AppLanguage> {
  final AppLanguage _initial;
  final SettingsStorage _storage;

  AppLanguageNotifier(this._initial, {SettingsStorage? storage}) : _storage = storage ?? SettingsStorage();

  @override
  AppLanguage build() => _initial;

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await _storage.write(_languageStorageKey, language.name);
  }
}

/// Reads back a previously persisted language, or `null` if none is stored
/// (or the stored value doesn't match a known [AppLanguage]).
Future<AppLanguage?> readPersistedLanguage(SettingsStorage storage) async {
  final raw = await storage.read(_languageStorageKey);
  if (raw == null) return null;
  for (final language in AppLanguage.values) {
    if (language.name == raw) return language;
  }
  return null;
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  () => AppLanguageNotifier(AppLanguage.fr),
);

final appLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(appLanguageProvider);
  return switch (language) {
    AppLanguage.fr => const Locale('fr'),
    AppLanguage.en => const Locale('en'),
  };
});
