import 'package:flutter/material.dart';

/// Roundedness scale for the "Monolith Architect" design system.
class AppRadii {
  AppRadii._();

  /// Buttons, inputs, chips.
  static const double interactive = 8.0;

  /// Cards, sheets, dialogs.
  static const double structural = 12.0;

  static BorderRadius get interactiveRadius => BorderRadius.circular(interactive);
  static BorderRadius get structuralRadius => BorderRadius.circular(structural);
}
