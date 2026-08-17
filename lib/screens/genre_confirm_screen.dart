import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/scan_queue_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';

/// Design screen 09 — genre confirm. Never auto-writes an unconfirmed
/// genre (`docs/Backlog shelf.md`) — Confirm is the only way a genre
/// reaches the queue item, even when [genre_matcher.suggestGenre] already
/// pre-selected one.
class GenreConfirmScreen extends ConsumerStatefulWidget {
  final String itemId;
  const GenreConfirmScreen({super.key, required this.itemId});

  @override
  ConsumerState<GenreConfirmScreen> createState() => _GenreConfirmScreenState();
}

class _GenreConfirmScreenState extends ConsumerState<GenreConfirmScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final queue = ref.watch(scanQueueProvider);
    final item = queue.where((i) => i.id == widget.itemId).firstOrNull;
    if (item == null) {
      return Scaffold(backgroundColor: tokens.bg, body: const SizedBox.shrink());
    }
    _selected ??= item.confirmedGenre;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.genreConfirmTitle, style: TextStyle(color: tokens.text, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: genreHues.keys
                    .map((genre) => _GenreChip(
                          tokens: tokens,
                          label: genre,
                          selected: _selected == genre,
                          onTap: () => setState(() => _selected = genre),
                        ))
                    .toList(),
              ),
              if (item.apiCategories != null) ...[
                const SizedBox(height: 14),
                Text(
                  '${l10n.fromApi} "${item.apiCategories}"',
                  style: TextStyle(color: tokens.muted, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          ref.read(scanQueueProvider.notifier).confirmGenre(widget.itemId, _selected!);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: tokens.track,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(l10n.confirm, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip({required this.tokens, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.accentSoft : tokens.surface,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: selected ? tokens.accent : tokens.border),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? tokens.accent : tokens.text, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
