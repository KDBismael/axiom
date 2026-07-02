import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for the "Monolith Architect" design system.
///
/// Letter-spacing is expressed in em in the spec, but Flutter's
/// [TextStyle.letterSpacing] is in logical pixels, so each style computes
/// `em * fontSize` rather than sharing one flat constant.
class AppTypography {
  AppTypography._();

  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 56,
        height: 1.1,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 28,
      );

  static TextStyle get titleLg => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  /// All-caps presentation is a caller concern (`.toUpperCase()`), not baked
  /// into the TextStyle.
  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 12,
      );
}
