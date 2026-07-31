import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/validations_controller.dart';
import '../models/ally_validation_request.dart';
import '../widgets/validation_card.dart';

/// Single-item validation screen reached by tapping a "Validation demandée"
/// notification — scopes straight to the proof that notification is about
/// instead of the full pending-validations list (`AllyValidationsView`).
class ValidationDetailView extends StatelessWidget {
  const ValidationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ValidationsController>();
    final evidenceId = Get.arguments as String;

    if (controller.validations.isEmpty && !controller.isLoading.value) {
      controller.loadValidations();
    }

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
                    'Validation',
                    style: AppTypography.displayLg.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    if (controller.isLoading.value && controller.validations.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.emerald),
                        ),
                      );
                    }

                    final matches = controller.validations.where(
                      (v) => v.evidenceId == evidenceId,
                    );
                    final request = matches.isEmpty ? null : matches.first;

                    if (request == null) {
                      return _NotFoundState(
                        onSeeAll: () => Get.offNamed(AppRoutes.allyValidations),
                      );
                    }

                    if (request.status != ValidationDecisionStatus.pending) {
                      return DecidedValidationCard(request: request);
                    }

                    return ValidationCard(
                      request: request,
                      onApprove: (comment) async {
                        await controller.decide(request.id, approved: true, comment: comment);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      onReject: (comment) async {
                        await controller.decide(request.id, approved: false, comment: comment);
                        if (context.mounted) Navigator.of(context).pop();
                      },
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

class _NotFoundState extends StatelessWidget {
  const _NotFoundState({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validation introuvable.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            'VOIR TOUTES LES VALIDATIONS',
            style: AppTypography.labelMd.copyWith(color: AppColors.emerald),
          ),
        ),
      ],
    );
  }
}
