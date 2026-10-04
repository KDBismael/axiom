import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';

/// A labeled, editable identity field (prénom, nom, ...).
class ProfileField extends StatelessWidget {
  const ProfileField({super.key, required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: const BorderSide(color: AppColors.volt),
            ),
          ),
        ),
      ],
    );
  }
}

/// Non-editable identity field — used for email, which the backend doesn't
/// allow changing via PATCH /profile/me.
class ProfileReadOnlyField extends StatelessWidget {
  const ProfileReadOnlyField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadii.interactiveRadius,
            border: Border.all(color: AppColors.outlineVariant15),
          ),
          child: Text(value, style: AppTypography.bodyMd.copyWith(color: AppColors.outline)),
        ),
      ],
    );
  }
}

/// The floating "unsaved changes" bar — shown above the keyboard/bottom
/// edge whenever [ProfileController.hasUnsavedChanges] is true, on any
/// screen that edits profile fields.
class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({super.key, required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border(top: BorderSide(color: AppColors.outlineVariant15)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Modifications non enregistrées',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 136,
            height: 40,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: AppColors.volt,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Text('ENREGISTRER', style: AppTypography.labelMd),
            ),
          ),
        ],
      ),
    );
  }
}
