import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../models/country.dart';

/// Dial-code picker + local-number field, shared by any screen that
/// collects a phone number (profile settings, registration).
class PhoneInputField extends StatelessWidget {
  const PhoneInputField({
    super.key,
    required this.country,
    required this.controller,
    this.label = 'NUMÉRO DE TÉLÉPHONE',
  });

  final Rx<Country> country;
  final TextEditingController controller;
  final String label;

  Future<void> _pickCountry(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.structuralRadius),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      'PAYS',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                    ),
                  ),
                  for (final option in xofZoneCountries)
                    ListTile(
                      title: Text(
                        '${option.name} (${option.dialCode})',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                      ),
                      trailing: option == country.value
                          ? const Icon(Icons.check, color: AppColors.emerald)
                          : null,
                      onTap: () {
                        country.value = option;
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => GestureDetector(
                onTap: () => _pickCountry(context),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: AppRadii.interactiveRadius,
                    border: Border.all(color: AppColors.outlineVariant15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.value.dialCode,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColors.outline, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: AppColors.emerald),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
