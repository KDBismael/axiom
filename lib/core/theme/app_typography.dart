import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for the "Ndeli — Arène" design system: Unbounded for
/// display/headline/CTA text, Geist for body copy, Geist Mono for the small
/// uppercase eyebrow labels and monospaced numbers.
///
/// Letter-spacing is expressed in em in the spec, but Flutter's
/// [TextStyle.letterSpacing] is in logical pixels, so each style computes
/// `em * fontSize` rather than sharing one flat constant.
class AppTypography {
  AppTypography._();

  static const _geist = 'Geist';
  static const _geistMono = 'Geist Mono';

  static TextStyle get displayLg => GoogleFonts.unbounded(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02 * 56,
        height: 1.1,
      );

  static TextStyle get headlineMd => GoogleFonts.unbounded(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.01 * 28,
        height: 1.1,
      );

  static TextStyle get titleLg => GoogleFonts.unbounded(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _geist,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// All-caps presentation is a caller concern (`.toUpperCase()`), not baked
  /// into the TextStyle.
  static const TextStyle labelMd = TextStyle(
    fontFamily: _geistMono,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14 * 12,
  );
}
