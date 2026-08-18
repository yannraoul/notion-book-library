import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'onboarding_screen.dart';

// Connection status dot — a fixed universal green, not one of the theme's
// accent/secondary tokens (those vary per selected theme and shouldn't be
// relied on to read as "connected" regardless of which one is active).
const _connectedDotColor = Color(0xFF34A853);

/// Notion connection (NBLM-3), Preferences — theme + language (NBLM-5),
/// and About Shelf + onboarding replay (NBLM-11) are all real now.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontalPadding,
                4,
                AppSpacing.screenHorizontalPadding,
                16,
              ),
              child: Text(l10n.settingsTitle, style: AppTypography.screenTitle(tokens.text)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(l10n.settingsNotion.toUpperCase(), style: AppTypography.sectionLabel(tokens.muted)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _NotionConnectionCard(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(l10n.settingsPreferences.toUpperCase(), style: AppTypography.sectionLabel(tokens.muted)),
            ),
            const _LanguageToggle(),
            const SizedBox(height: 12),
            const _ThemeSelector(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text(l10n.settingsAbout.toUpperCase(), style: AppTypography.sectionLabel(tokens.muted)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsAboutBody, style: AppTypography.bodyMuted(tokens.muted)),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen(standalone: false)),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, alignment: Alignment.centerLeft),
                    child: Text(l10n.settingsViewOnboarding, style: TextStyle(color: tokens.accent, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends ConsumerWidget {
  const _LanguageToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final l10n = AppLocalizations.of(context)!;
    final language = ref.watch(appLanguageProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
      child: Row(
        children: [
          Text(l10n.settingsLanguage, style: AppTypography.bodyMuted(tokens.muted)),
          const SizedBox(width: 12),
          _SegmentedOption(
            label: 'Français',
            selected: language == AppLanguage.fr,
            tokens: tokens,
            onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.fr),
          ),
          const SizedBox(width: 8),
          _SegmentedOption(
            label: 'English',
            selected: language == AppLanguage.en,
            tokens: tokens,
            onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final l10n = AppLocalizations.of(context)!;
    final selectedTheme = ref.watch(appThemeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsAccent, style: AppTypography.bodyMuted(tokens.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final theme in AppTheme.values)
                _ThemeOption(
                  label: _themeLabel(theme, l10n),
                  swatch: AppColorTokens.forTheme(theme),
                  selected: theme == selectedTheme,
                  tokens: tokens,
                  onTap: () => ref.read(appThemeProvider.notifier).setTheme(theme),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _themeLabel(AppTheme theme, AppLocalizations l10n) => switch (theme) {
        AppTheme.terracotta => l10n.themeTerracotta,
        AppTheme.vertRouge => l10n.themeVertRouge,
        AppTheme.ambreArdoise => l10n.themeAmbreArdoise,
        AppTheme.sarcelleRouille => l10n.themeSarcelleRouille,
      };
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final AppColorTokens swatch;
  final bool selected;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.swatch,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.surface : Colors.transparent,
          border: Border.all(color: selected ? tokens.text : tokens.border, width: 1),
          borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeSwatchDot(color: swatch.accent),
            const SizedBox(width: 4),
            _ThemeSwatchDot(color: swatch.secondary),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.rowSubtitle(selected ? tokens.text : tokens.muted)),
          ],
        ),
      ),
    );
  }
}

class _ThemeSwatchDot extends StatelessWidget {
  final Color color;
  const _ThemeSwatchDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SegmentedOption extends StatelessWidget {
  final String label;
  final bool selected;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _SegmentedOption({
    required this.label,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.surface : Colors.transparent,
          border: Border.all(color: selected ? tokens.text : tokens.border, width: 1),
          borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
        ),
        child: Text(label, style: AppTypography.rowSubtitle(selected ? tokens.text : tokens.muted)),
      ),
    );
  }
}

class _NotionConnectionCard extends ConsumerStatefulWidget {
  const _NotionConnectionCard();

  @override
  ConsumerState<_NotionConnectionCard> createState() => _NotionConnectionCardState();
}

class _NotionConnectionCardState extends ConsumerState<_NotionConnectionCard> {
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notionConnectionProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.cardPaddingVertical,
        horizontal: AppSpacing.cardPaddingHorizontal,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border, width: 1),
        borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
      ),
      child: switch (state) {
        NotionConnected(:final workspaceName, :final databases) =>
          _ConnectedBody(tokens: tokens, l10n: l10n, workspaceName: workspaceName, databases: databases),
        NotionConnecting() => _ConnectingBody(tokens: tokens, l10n: l10n),
        NotionDisconnected() => _DisconnectedBody(tokens: tokens, l10n: l10n, controller: _tokenController),
        NotionConnectionError(:final message) =>
          _DisconnectedBody(tokens: tokens, l10n: l10n, controller: _tokenController, errorMessage: message),
      },
    );
  }
}

class _ConnectedBody extends ConsumerWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final String workspaceName;
  final List<NotionDatabaseSummary> databases;

  const _ConnectedBody({
    required this.tokens,
    required this.l10n,
    required this.workspaceName,
    required this.databases,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tokens.dark, borderRadius: BorderRadius.circular(9)),
              child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsConnected,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.text),
                  ),
                  Text(workspaceName, style: AppTypography.rowSubtitle(tokens.muted)),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: _connectedDotColor, shape: BoxShape.circle),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.settingsAccessibleDatabases, style: AppTypography.rowSubtitle(tokens.muted)),
        const SizedBox(height: 6),
        if (databases.isEmpty)
          Text(l10n.settingsNoDatabasesFound, style: AppTypography.bodyMuted(tokens.muted))
        else
          for (final db in databases)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${db.title}', style: AppTypography.bodyMuted(tokens.text)),
            ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => ref.read(notionConnectionProvider.notifier).disconnect(),
          child: Text(
            l10n.settingsDisconnect,
            style: AppTypography.rowSubtitle(tokens.accent).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ConnectingBody extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;

  const _ConnectingBody({required this.tokens, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: tokens.accent),
        ),
        const SizedBox(width: 12),
        Text(l10n.settingsConnecting, style: AppTypography.bodyMuted(tokens.muted)),
      ],
    );
  }
}

class _DisconnectedBody extends ConsumerWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final TextEditingController controller;
  final String? errorMessage;

  const _DisconnectedBody({
    required this.tokens,
    required this.l10n,
    required this.controller,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          Text(errorMessage!, style: AppTypography.bodyMuted(tokens.alert)),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            hintText: l10n.settingsNotionTokenHint,
            hintStyle: AppTypography.bodyMuted(tokens.muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              final token = controller.text.trim();
              if (token.isEmpty) return;
              ref.read(notionConnectionProvider.notifier).connect(token);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tokens.accent,
                borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
              ),
              child: Text(
                l10n.settingsConnect,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
