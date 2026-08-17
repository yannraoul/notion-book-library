import 'dart:ui';

import 'oklch.dart';

/// The 4 selectable themes from the design spec — shared with the sister
/// Habits app for visual-identity consistency across the two apps.
enum AppTheme { terracotta, vertRouge, ambreArdoise, sarcelleRouille }

class AppColorTokens {
  final Color bg;
  final Color surface;
  final Color text;
  final Color muted;
  final Color border;
  final Color track;
  final Color dark;
  final Color alert;
  final Color accent;
  final Color accentSoft;
  final Color secondary;
  final Color secondarySoft;

  const AppColorTokens({
    required this.bg,
    required this.surface,
    required this.text,
    required this.muted,
    required this.border,
    required this.track,
    required this.dark,
    required this.alert,
    required this.accent,
    required this.accentSoft,
    required this.secondary,
    required this.secondarySoft,
  });

  /// [brightness] drives only the neutral tokens (`bg`/`surface`/`text`/
  /// `muted`/`border`/`track`/`dark`/`alert`) — `accent`/`secondary` stay
  /// theme-defined and unchanged across light/dark, same convention as the
  /// sister Habits app. Unlike Habits, Shelf has no accent=good/secondary=bad
  /// polarity to carry — `accent` is just the primary action color here,
  /// and genre identity is carried separately by `genreColor()` below.
  factory AppColorTokens.forTheme(
    AppTheme theme, {
    Brightness brightness = Brightness.light,
  }) {
    final pair = _themePairs[theme]!;
    final isDark = brightness == Brightness.dark;
    return AppColorTokens(
      bg: isDark ? oklch(0.19, 0.008, 75) : oklch(0.97, 0.006, 75),
      surface: isDark ? oklch(0.24, 0.008, 75) : oklch(0.995, 0.002, 75),
      text: isDark ? oklch(0.95, 0.005, 75) : oklch(0.22, 0.01, 60),
      muted: isDark ? oklch(0.65, 0.01, 75) : oklch(0.55, 0.01, 60),
      border: isDark ? oklch(0.32, 0.01, 75) : oklch(0.9, 0.006, 75),
      track: isDark ? oklch(0.32, 0.01, 75) : oklch(0.9, 0.006, 75),
      dark: isDark ? oklch(0.55, 0.01, 75) : oklch(0.32, 0.01, 60),
      alert: isDark ? oklch(0.68, 0.15, 30) : oklch(0.55, 0.15, 30),
      accent: pair.accent,
      accentSoft: pair.accentSoft,
      secondary: pair.secondary,
      secondarySoft: pair.secondarySoft,
    );
  }
}

class _ThemePair {
  final Color accent;
  final Color accentSoft;
  final Color secondary;
  final Color secondarySoft;

  const _ThemePair({
    required this.accent,
    required this.accentSoft,
    required this.secondary,
    required this.secondarySoft,
  });
}

final Map<AppTheme, _ThemePair> _themePairs = {
  AppTheme.terracotta: _ThemePair(
    accent: oklch(0.62, 0.15, 45),
    accentSoft: oklch(0.94, 0.03, 45),
    secondary: oklch(0.55, 0.08, 120),
    secondarySoft: oklch(0.93, 0.03, 120),
  ),
  AppTheme.vertRouge: _ThemePair(
    accent: oklch(0.58, 0.13, 145),
    accentSoft: oklch(0.94, 0.03, 145),
    secondary: oklch(0.56, 0.15, 30),
    secondarySoft: oklch(0.94, 0.03, 30),
  ),
  AppTheme.ambreArdoise: _ThemePair(
    accent: oklch(0.72, 0.14, 75),
    accentSoft: oklch(0.95, 0.03, 75),
    secondary: oklch(0.52, 0.08, 250),
    secondarySoft: oklch(0.93, 0.02, 250),
  ),
  AppTheme.sarcelleRouille: _ThemePair(
    accent: oklch(0.6, 0.1, 195),
    accentSoft: oklch(0.94, 0.02, 195),
    secondary: oklch(0.56, 0.14, 40),
    secondarySoft: oklch(0.94, 0.03, 40),
  ),
};

/// Genres get a fixed cover color, independent of theme/light-dark mode —
/// Shelf's own use of color, distinct from the accent/secondary system
/// above. Hue values from `design/design_handoff_shelf/README.md`.
///
/// NOTE: this genre id/hue list (from the design prototype) doesn't match
/// `docs/Backlog shelf.md`'s Notion `Genres` db list (Fantasy,
/// Science-fiction, Finances, Personal development, Productivity, Business,
/// LitRPG) — see `planning/BACKLOG.md` for the open reconciliation item.
const Map<String, double> genreHues = {
  'fiction': 260,
  'scifi': 195,
  'fantasy': 300,
  'business': 90,
  'selfhelp': 20,
  'nonfiction': 230,
  'biography': 350,
  'history': 140,
};

Color genreColor(String genreId) {
  final hue = genreHues[genreId] ?? 0;
  return oklch(0.5, 0.1, hue);
}
