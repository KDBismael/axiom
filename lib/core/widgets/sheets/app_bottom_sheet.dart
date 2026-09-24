import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';

/// The bottom sheet chrome from the "Ndeli — Arène" design system: a dark
/// scrim, a sheet sliding up from the bottom with `26px` top corners, and a
/// drag handle — used for the pause ("Mode malade") and delete
/// ("Supprimer la quête") confirmations.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surfaceContainerLow,
    barrierColor: AppColors.ambientVoidShadow.withValues(alpha: 0.6),
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      side: BorderSide(color: AppColors.outlineVariantStrong),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBright,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            builder(sheetContext),
          ],
        ),
      ),
    ),
  );
}
