import 'dart:io';

import 'package:flutter/services.dart';

import '../theme/color_tokens.dart';

const _channel = MethodChannel('notion_book_library/app_icon');

/// iOS-only: switches the home-screen icon to match [theme] via
/// `UIApplication.setAlternateIconName` (see `ios/Runner/AppDelegate.swift`
/// and the `AppIcon`/`AppIcon-*` sets in `ios/Runner/Assets.xcassets`). A
/// `null` icon name restores the primary icon. No-ops entirely on Android/
/// Windows dev builds. Icon-switching is cosmetic — any platform failure is
/// swallowed rather than surfaced, so it can never make a theme change look
/// like it failed.
Future<void> setAppIcon(AppTheme theme) async {
  if (!Platform.isIOS) return;
  try {
    await _channel.invokeMethod('setAlternateIconName', _iconNameFor(theme));
  } on PlatformException {
    // Cosmetic only — ignored.
  }
}

String? _iconNameFor(AppTheme theme) {
  switch (theme) {
    case AppTheme.terracotta:
      return null; // primary/default icon
    case AppTheme.vertRouge:
      return 'AppIcon-VertRouge';
    case AppTheme.ambreArdoise:
      return 'AppIcon-AmbreArdoise';
    case AppTheme.sarcelleRouille:
      return 'AppIcon-SarcelleRouille';
  }
}
