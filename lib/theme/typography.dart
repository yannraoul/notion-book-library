import 'package:flutter/widgets.dart';

/// `letter-spacing` in the design spec is expressed in CSS `em` units
/// (relative to font size), e.g. `0.04em` on a 13px label is 0.52px — not a
/// literal pixel value.
double emLetterSpacing(double fontSize, double em) => fontSize * em;

/// Named text styles for the scale used across Shelf's screens. Deliberately
/// don't set `fontFamily` here — it's left to inherit the platform-aware
/// family set on the app's [ThemeData], same convention as `color_tokens.dart`
/// not owning platform concerns either.
class AppTypography {
  AppTypography._();

  static TextStyle screenTitle(Color color) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle sectionLabel(Color color) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: emLetterSpacing(13, 0.04),
        color: color,
      );

  static TextStyle bodyMuted(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle rowSubtitle(Color color) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle pillLabel(Color color) => TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: emLetterSpacing(10.5, 0.03),
        color: color,
      );

  static TextStyle navLabel(Color color) => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle detailTitle(Color color) => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: color,
      );
}
