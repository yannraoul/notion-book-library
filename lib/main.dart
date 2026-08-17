import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'screens/root_shell.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));

    return MaterialApp(
      title: 'Shelf',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
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
      home: const RootShell(),
    );
  }
}
