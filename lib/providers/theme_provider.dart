import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/color_tokens.dart';

/// Hardcoded default until Settings gets a real theme switcher + persistence
/// (a future milestone) — kept as its own provider now so that milestone
/// only has to change what feeds this, not every place tokens are read.
final _appThemeProvider = Provider<AppTheme>((ref) => AppTheme.terracotta);

/// Same reusable shape as the sister Habits app's own `colorTokensProvider`:
/// derives tokens from the selected theme and the current platform
/// brightness. `brightness` is passed in by the caller (from
/// `MediaQuery.platformBrightnessOf(context)`) rather than read here, since
/// providers shouldn't depend on `BuildContext`.
final colorTokensProvider = Provider.family<AppColorTokens, Brightness>((ref, brightness) {
  final theme = ref.watch(_appThemeProvider);
  return AppColorTokens.forTheme(theme, brightness: brightness);
});
