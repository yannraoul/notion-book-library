import 'dart:math';
import 'dart:ui';

/// Converts an OKLCH color (as used throughout the design spec, e.g.
/// `oklch(0.62 0.15 45)`) to a Flutter [Color]. There is no `oklch()`
/// equivalent in Dart/Flutter, so this hand-rolls the OKLab round-trip
/// (Björn Ottosson's published conversion matrices).
Color oklch(double lightness, double chroma, double hueDegrees, [double alpha = 1.0]) {
  final hueRad = hueDegrees * pi / 180;
  final a = chroma * cos(hueRad);
  final b = chroma * sin(hueRad);

  final lPrime = lightness + 0.3963377774 * a + 0.2158037573 * b;
  final mPrime = lightness - 0.1055613458 * a - 0.0638541728 * b;
  final sPrime = lightness - 0.0894841775 * a - 1.2914855480 * b;

  final l = lPrime * lPrime * lPrime;
  final m = mPrime * mPrime * mPrime;
  final s = sPrime * sPrime * sPrime;

  final rLinear = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
  final gLinear = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
  final bLinear = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

  return Color.from(
    alpha: alpha,
    red: _linearToSrgb(rLinear),
    green: _linearToSrgb(gLinear),
    blue: _linearToSrgb(bLinear),
  );
}

double _linearToSrgb(double channel) {
  final clamped = channel.clamp(0.0, 1.0);
  final srgb = clamped <= 0.0031308
      ? clamped * 12.92
      : 1.055 * pow(clamped, 1 / 2.4) - 0.055;
  return srgb.clamp(0.0, 1.0);
}
