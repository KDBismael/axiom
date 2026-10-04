import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A small fixed palette of accent colors used to fill an initials chip
/// (ally lists, the leaderboard) — deterministic per id, so the same person
/// always gets the same color across screens without the backend having to
/// assign or persist one.
const _avatarPalette = [
  AppColors.volt,
  AppColors.ember,
  AppColors.violet,
  AppColors.gold,
  AppColors.waveCyan,
  AppColors.emberBright,
  AppColors.amber,
  AppColors.errorSoft,
];

Color avatarColorForId(String id) {
  if (id.isEmpty) return _avatarPalette.first;
  return _avatarPalette[id.hashCode.abs() % _avatarPalette.length];
}

/// Up to 2 uppercase initials from a first/last name, falling back to '?'.
String initialsFor(String firstName, String lastName) {
  final first = firstName.trim();
  final last = lastName.trim();
  final buffer = StringBuffer();
  if (first.isNotEmpty) buffer.write(first[0].toUpperCase());
  if (last.isNotEmpty) buffer.write(last[0].toUpperCase());
  return buffer.isEmpty ? '?' : buffer.toString();
}

/// Two-letter initials for names received as one display-name string.
String initialsForDisplayName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    return word.length > 1
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }
  return initialsFor(parts.first, parts.last);
}
