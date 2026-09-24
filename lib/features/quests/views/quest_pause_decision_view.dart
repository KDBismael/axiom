import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/quest_list_controller.dart';
import '../controllers/quest_pause_decision_controller.dart';
import '../models/quest_pause_request.dart';

class QuestPauseDecisionView extends GetView<QuestPauseDecisionController> {
  const QuestPauseDecisionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.isLoading.value && controller.request.value == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.volt),
              );
            }
            final request = controller.request.value;
            if (request == null) {
              return Center(
                child: Text(
                  controller.errorMessage.value ?? 'Demande introuvable.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DEMANDE DE PAUSE',
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 12),
                Text(
                  "Un allié souhaite mettre cette quête en pause. En l'approuvant, "
                  "les pointages sont suspendus et l'échéance sera repoussée "
                  "d'autant à la reprise.",
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
                if (request.description != null &&
                    request.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.description!,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (request.status == QuestPauseRequestStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.isDeciding.value
                              ? null
                              : () async {
                                  final ok = await controller.decide(
                                    approve: false,
                                  );
                                  if (ok) {
                                    await Get.find<QuestListController>()
                                        .loadPendingPauseRequests();
                                    Get.back();
                                  }
                                },
                          child: const Text('REFUSER'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          label: 'APPROUVER',
                          loading: controller.isDeciding.value,
                          onPressed: controller.isDeciding.value
                              ? null
                              : () async {
                                  final ok = await controller.decide(
                                    approve: true,
                                  );
                                  if (ok) {
                                    await Get.find<QuestListController>()
                                        .loadPendingPauseRequests();
                                    Get.back();
                                  }
                                },
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Cette demande a déjà été traitée.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
