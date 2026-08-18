import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/authors_provider.dart';
import '../providers/theme_provider.dart';
import '../services/author_matcher.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import 'confidence_pill.dart';

/// Chip/tag input for a book's authors — chips and the text field share a
/// single bordered box (like a normal tag input), with a live dropdown
/// below: existing `Authors*` names that contain what's typed (a normal
/// substring/prefix search) first, then near-duplicate spelling/initials
/// variants from [rankAuthorMatches] with a confidence pill (e.g. "F. C.
/// Yee" surfacing "Fonda C. Yee") for names that wouldn't turn up as a
/// plain substring match. An explicit "add as new" option is always last
/// unless what's typed already exactly matches an existing name.
///
/// Deliberately never calls `createRelationPage` itself: it only ever
/// produces/consumes a plain `List<String>` of display names, identical in
/// shape to the old comma-separated text field it replaces. Actual
/// `Authors*` page creation stays exclusively inside
/// `BooksRepository.resolveAuthorIds` at save/commit time — this widget's
/// entire job is making sure the name that reaches that step is already
/// the canonical one whenever a close match exists.
///
/// A deliberate deviation from the design spec's literal single full-width
/// free-text field for Authors (screens 09/10) — see `planning/features/
/// NBLM-12.md`.
class AuthorChipInput extends ConsumerStatefulWidget {
  final List<String> authors;
  final ValueChanged<List<String>> onChanged;

  const AuthorChipInput({super.key, required this.authors, required this.onChanged});

  @override
  ConsumerState<AuthorChipInput> createState() => _AuthorChipInputState();
}

class _AuthorChipInputState extends ConsumerState<AuthorChipInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _query = '';

  /// Dropdown visibility is deliberately query-driven, not
  /// `_focusNode.hasFocus`-driven: tapping a candidate row is itself a tap
  /// on a focusable widget, which the framework resolves by shifting
  /// primary focus away from the text field *before* the row's own
  /// `onTap` fires — gating visibility on focus made the dropdown unmount
  /// mid-gesture, so a tap silently did nothing (confirmed live: the raw
  /// typed text was left in place with no chip added). [TapRegion] below
  /// closes it on a genuine tap elsewhere instead. The focus listener here
  /// only drives the outer box's border color, a separate concern.
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || widget.authors.contains(trimmed)) return;
    widget.onChanged([...widget.authors, trimmed]);
    _controller.clear();
    setState(() {
      _query = '';
      _dismissed = false;
    });
  }

  void _remove(String name) {
    widget.onChanged(widget.authors.where((a) => a != name).toList());
  }

  /// Ranked dropdown rows: substring/prefix matches against the live
  /// `Authors*` list first (normal typeahead), then near-duplicate
  /// spelling/initials variants from [rankAuthorMatches] for names a plain
  /// substring search wouldn't surface — deduped, capped at 5.
  List<(String name, double? confidence)> _candidateRows(String query, Iterable<String> existingNames) {
    final normalizedQuery = query.toLowerCase();
    final available = existingNames.where((name) => !widget.authors.contains(name)).toSet();

    final prefixMatches = available.where((n) => n.toLowerCase().startsWith(normalizedQuery)).toList()..sort();
    final containsMatches = available.where((n) => !n.toLowerCase().startsWith(normalizedQuery) && n.toLowerCase().contains(normalizedQuery)).toList()
      ..sort();
    final fuzzyMatches = rankAuthorMatches(query, available);

    final seen = <String>{};
    final rows = <(String, double?)>[];
    for (final n in prefixMatches) {
      if (seen.add(n)) rows.add((n, null));
    }
    for (final n in containsMatches) {
      if (seen.add(n)) rows.add((n, null));
    }
    for (final m in fuzzyMatches) {
      if (seen.add(m.existingName)) rows.add((m.existingName, m.confidence));
    }
    return rows.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final existingAuthors = ref.watch(authorNamesProvider).valueOrNull ?? const {};

    final trimmedQuery = _query.trim();
    final candidateRows = trimmedQuery.isEmpty ? const <(String, double?)>[] : _candidateRows(trimmedQuery, existingAuthors.values);
    final exactMatchExists = candidateRows.any((row) => isExactMatch(row.$1, trimmedQuery));
    final showDropdown = !_dismissed && trimmedQuery.isNotEmpty;

    return TapRegion(
      onTapOutside: (_) => setState(() => _dismissed = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
              border: Border.all(color: _focusNode.hasFocus ? tokens.accent : tokens.border, width: _focusNode.hasFocus ? 1.5 : 1),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final name in widget.authors) _AuthorChip(tokens: tokens, label: name, onRemove: () => _remove(name)),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 120),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (value) => setState(() {
                        _query = value;
                        _dismissed = false;
                      }),
                      onSubmitted: _add,
                      style: TextStyle(color: tokens.text, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.authors.isEmpty ? l10n.authorChipHint : null,
                        hintStyle: TextStyle(color: tokens.muted, fontSize: 12.5),
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDropdown)
            Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in candidateRows)
                    _CandidateRow(tokens: tokens, label: row.$1, confidence: row.$2, onTap: () => _add(row.$1)),
                  if (!exactMatchExists)
                    _CandidateRow(
                      tokens: tokens,
                      label: l10n.authorAddNew(trimmedQuery),
                      confidence: null,
                      onTap: () => _add(trimmedQuery),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthorChip extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final VoidCallback onRemove;

  const _AuthorChip({required this.tokens, required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: tokens.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: tokens.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            child: Icon(Icons.close, size: 15, color: tokens.accent),
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final double? confidence;
  final VoidCallback onTap;

  const _CandidateRow({required this.tokens, required this.label, required this.confidence, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: tokens.text, fontSize: 13.5))),
            if (confidence != null) ConfidencePill(tokens: tokens, value: confidence!),
          ],
        ),
      ),
    );
  }
}
