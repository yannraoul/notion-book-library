import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing.dart';

/// Toggleable genre pill — selected = filled `accentSoft` bg + `accent`
/// border/text, matching the design spec's manual-entry/genre-confirm chip
/// pattern (screens 09/09). Shared by manual entry, genre confirm, and book
/// detail.
class GenreChip extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const GenreChip({super.key, required this.tokens, required this.label, required this.selected, required this.onTap});

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
