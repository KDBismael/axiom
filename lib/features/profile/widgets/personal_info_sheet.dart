import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/profile_controller.dart';
import 'phone_input_field.dart';
import 'profile_editable_fields.dart';

/// "Informations personnelles" — name/email/phone, opened as a bottom sheet
/// from the Profile tab's settings row (matches the mockup's `sheetInvite`
/// treatment: drag handle, eyebrow + title, fields, a pill CTA, "Annuler").
class PersonalInfoSheet extends StatefulWidget {
  const PersonalInfoSheet({super.key});

  @override
  State<PersonalInfoSheet> createState() => _PersonalInfoSheetState();
}

class _PersonalInfoSheetState extends State<PersonalInfoSheet> {
  Future<void> _save(ProfileController controller) async {
    await controller.save();
    if (!mounted || controller.errorMessage.value != null) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Modifications enregistrées.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancel(ProfileController controller) {
    controller.discardChanges();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PARAMÈTRES',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Informations personnelles',
              style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ProfileField(
                    label: 'PRÉNOM',
                    controller: controller.firstNameController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ProfileField(
                    label: 'NOM',
                    controller: controller.lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(
              () => ProfileReadOnlyField(
                label: 'E-MAIL',
                value: controller.profile.value?.email ?? '',
              ),
            ),
            const SizedBox(height: 20),
            PhoneInputField(
              country: controller.country,
              controller: controller.phoneController,
              label: 'NUMÉRO WAVE',
            ),
            Obx(() {
              final error = controller.errorMessage.value;
              if (error == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error,
                  style: AppTypography.labelMd.copyWith(color: AppColors.error),
                ),
              );
            }),
            const SizedBox(height: 28),
            Obx(() {
              final saving = controller.isSaving.value;
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: AppPressable(
                  color: AppColors.volt,
                  shadowColor: AppColors.voltShadow,
                  shadowThickness: 5,
                  borderRadius: BorderRadius.circular(28),
                  enabled: !saving,
                  onTap: () => _save(controller),
                  child: Center(
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text(
                            'ENREGISTRER',
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.onPrimary,
                            ),
                          ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => _cancel(controller),
                child: const Text(
                  'Annuler',
                  style: TextStyle(fontSize: 14, color: AppColors.outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
