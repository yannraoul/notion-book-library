import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/scan_queue_provider.dart';
import '../providers/theme_provider.dart';
import '../services/author_matcher.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../widgets/confidence_pill.dart';

/// Author-confirm — one section per ambiguous scanned author name on this
/// queue item (`item.ambiguousAuthors`), each showing the raw scanned name
/// and its ranked existing-`Authors*` candidates (confidence pill, same
/// visual language as the OCR ranked-list screen), plus an explicit "keep
/// as new" option. Never auto-writes: [ScanQueueNotifier.confirmAuthor]
/// only runs on an explicit selection, mirroring [GenreConfirmScreen]'s
/// "Confirm is the only way" rule.
class AuthorConfirmScreen extends ConsumerStatefulWidget {
  final String itemId;
  const AuthorConfirmScreen({super.key, required this.itemId});

  @override
  ConsumerState<AuthorConfirmScreen> createState() => _AuthorConfirmScreenState();
}

class _AuthorConfirmScreenState extends ConsumerState<AuthorConfirmScreen> {
  final Map<String, String> _selections = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final queue = ref.watch(scanQueueProvider);
    final item = queue.where((i) => i.id == widget.itemId).firstOrNull;
    if (item == null || item.ambiguousAuthors.isEmpty) {
      return Scaffold(backgroundColor: tokens.bg, body: const SizedBox.shrink());
    }
    final allSelected = item.ambiguousAuthors.keys.every(_selections.containsKey);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.authorConfirmTitle, style: TextStyle(color: tokens.text, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: item.ambiguousAuthors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 20),
                  itemBuilder: (context, i) {
                    final entry = item.ambiguousAuthors.entries.elementAt(i);
                    return _AuthorSection(
                      tokens: tokens,
                      l10n: l10n,
                      rawName: entry.key,
                      candidates: entry.value,
                      selected: _selections[entry.key],
                      onSelect: (value) => setState(() => _selections[entry.key] = value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !allSelected
                      ? null
                      : () {
                          final notifier = ref.read(scanQueueProvider.notifier);
                          for (final entry in _selections.entries) {
                            notifier.confirmAuthor(widget.itemId, entry.key, entry.value);
                          }
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

class _AuthorSection extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final String rawName;
  final List<AuthorMatch> candidates;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _AuthorSection({
    required this.tokens,
    required this.l10n,
    required this.rawName,
    required this.candidates,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rawName, style: TextStyle(color: tokens.text, fontSize: 14.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final candidate in candidates)
                _OptionRow(
                  tokens: tokens,
                  label: candidate.existingName,
                  confidence: candidate.confidence,
                  selected: selected == candidate.existingName,
                  onTap: () => onSelect(candidate.existingName),
                ),
              _OptionRow(
                tokens: tokens,
                label: l10n.authorConfirmKeepNew(rawName),
                confidence: null,
                selected: selected == rawName,
                onTap: () => onSelect(rawName),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final double? confidence;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.tokens,
    required this.label,
    required this.confidence,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: selected ? tokens.accentSoft : null),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? tokens.accent : tokens.muted,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(color: tokens.text, fontSize: 13.5))),
            if (confidence != null) ConfidencePill(tokens: tokens, value: confidence!),
          ],
        ),
      ),
    );
  }
}
