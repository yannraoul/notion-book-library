import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/scan_queue_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';

/// Design screen 08 — dedupe dialog. "Fill in missing details" and "Add
/// as separate book" both mark the item ready (per the design prototype's
/// own note: a real merge into the *existing* Notion row happens on
/// save for "fill missing" — [QueueItem] doesn't need to represent that
/// distinction beyond ready/not-ready, [ScanQueueNotifier.commitReady]
/// always creates a fresh page either way for now).
class DedupeScreen extends ConsumerWidget {
  final String itemId;
  const DedupeScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final queue = ref.watch(scanQueueProvider);
    final item = queue.where((i) => i.id == itemId).firstOrNull;
    if (item == null || item.duplicateOf == null) {
      return Scaffold(backgroundColor: tokens.bg, body: const SizedBox.shrink());
    }
    final existing = item.duplicateOf!;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dedupeTitle, style: TextStyle(color: tokens.text, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.dedupeSubtitle, style: TextStyle(color: tokens.muted, fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Column(
                      tokens: tokens,
                      label: l10n.onShelf,
                      title: existing.title,
                      isbn: existing.isbn,
                      pages: existing.pages,
                      missingColor: true,
                      l10n: l10n,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Column(
                      tokens: tokens,
                      label: l10n.thisScan,
                      title: item.title,
                      isbn: item.isbn,
                      pages: item.pages,
                      missingColor: false,
                      l10n: l10n,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(scanQueueProvider.notifier).resolveFillMissing(itemId);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(l10n.fillMissing, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(scanQueueProvider.notifier).resolveAddSeparate(itemId);
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.text,
                    side: BorderSide(color: tokens.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(l10n.addSeparate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel, style: TextStyle(color: tokens.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final String title;
  final String? isbn;
  final int? pages;
  final bool missingColor;
  final AppLocalizations l10n;

  const _Column({
    required this.tokens,
    required this.label,
    required this.title,
    required this.isbn,
    required this.pages,
    required this.missingColor,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: tokens.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: tokens.text, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          '${l10n.detailIsbn}: ${isbn ?? (missingColor ? l10n.missing : '—')}',
          style: TextStyle(color: isbn == null && missingColor ? tokens.alert : tokens.muted, fontSize: 12.5),
        ),
        Text(
          '${l10n.detailPages}: ${pages ?? (missingColor ? l10n.missing : '—')}',
          style: TextStyle(color: pages == null && missingColor ? tokens.alert : tokens.muted, fontSize: 12.5),
        ),
      ],
    );
  }
}
