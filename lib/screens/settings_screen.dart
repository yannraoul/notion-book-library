import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Placeholder only — real content (Notion connection card, language/
/// appearance/accent sections) is a separate future milestone.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsTitle, style: AppTypography.screenTitle(tokens.text)),
            const SizedBox(height: 24),
            Text(l10n.comingSoon, style: AppTypography.bodyMuted(tokens.muted)),
          ],
        ),
      ),
    );
  }
}
