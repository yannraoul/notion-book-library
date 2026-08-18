import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/root_shell.dart';
import 'services/settings_storage.dart';
import 'theme/color_tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SettingsStorage();
  final initialTheme = await readPersistedTheme(storage) ?? AppTheme.terracotta;
  final initialLanguage = await readPersistedLanguage(storage) ?? AppLanguage.fr;
  final hasSeenOnboarding = await storage.read(hasSeenOnboardingKey) != null;

  runApp(
    ProviderScope(
      overrides: [
        appThemeProvider.overrideWith(() => AppThemeNotifier(initialTheme, storage: storage)),
        appLanguageProvider.overrideWith(() => AppLanguageNotifier(initialLanguage, storage: storage)),
      ],
      child: MyApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp(
      title: 'Shelf',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: tokens.accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: tokens.bg,
        fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: tokens.accent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: tokens.bg,
        fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
      ),
      home: showOnboarding ? const OnboardingScreen() : const RootShell(),
    );
  }
}
