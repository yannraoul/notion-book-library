import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

// Connection status dot — a fixed universal green, not one of the theme's
// accent/secondary tokens (those vary per selected theme and shouldn't be
// relied on to read as "connected" regardless of which one is active).
const _connectedDotColor = Color(0xFF34A853);

/// Notion connection card is real (NBLM-3); everything else
/// (Language/Appearance/Accent/About) is a separate future milestone.
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(l10n.comingSoon, style: AppTypography.bodyMuted(tokens.muted)),
            ),
          ],
        ),
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
