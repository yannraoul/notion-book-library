import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing.dart';

/// `accentSoft`-filled percentage pill for a match/lookup confidence score
/// (`0.0`-`1.0`) — the "confidence % pill" from the OCR ranked-list design
/// (screen 06), also used for author-match candidates.
class ConfidencePill extends StatelessWidget {
  final AppColorTokens tokens;
  final double value;

  const ConfidencePill({super.key, required this.tokens, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: tokens.accentSoft, borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
      child: Text(
        '${(value * 100).round()}%',
        style: TextStyle(color: tokens.accent, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
