import 'package:flutter/material.dart';

/// Roundedness scale for the "Ndeli — Arène" design system.
class AppRadii {
  AppRadii._();

  /// Buttons, inputs, chips, small icon-buttons.
  static const double interactive = 14.0;

  /// Cards, rows, standard containers.
  static const double structural = 20.0;

  /// Hero cards, bottom sheets, dialogs.
  static const double sheet = 26.0;

  static BorderRadius get interactiveRadius => BorderRadius.circular(interactive);
  static BorderRadius get structuralRadius => BorderRadius.circular(structural);
  static BorderRadius get sheetRadius => BorderRadius.circular(sheet);
}
