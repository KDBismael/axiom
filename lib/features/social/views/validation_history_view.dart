import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/validations_controller.dart';
import '../widgets/validation_card.dart';

/// History of validations I've already decided (approved or rejected) —
/// reachable from Profile, separate from the pending-validations list.
class ValidationHistoryView extends StatelessWidget {
  const ValidationHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ValidationsController>();
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique',
                    style: AppTypography.displayLg.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QUÊTES APPROUVÉES OU REJETÉES',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    final decided = controller.decidedValidations;
                    if (decided.isEmpty) return const _EmptyState();
                    return Column(
                      children: [
                        for (final request in decided) ...[
                          DecidedValidationCard(request: request),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.history, color: AppColors.outlineVariant, size: 36),
          const SizedBox(height: 12),
          Text(
            'AUCUNE VALIDATION TRAITÉE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outlineVariant),
          ),
        ],
      ),
    );
  }
}
