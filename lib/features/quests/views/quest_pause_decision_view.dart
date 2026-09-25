import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/quest_list_controller.dart';
import '../controllers/quest_pause_decision_controller.dart';
import '../models/quest_pause_request.dart';

/// The INBOX approve/reject card pattern, applied to a pause ("Mode
/// malade") decision — no literal mockup for the approver's side.
class QuestPauseDecisionView extends GetView<QuestPauseDecisionController> {
  const QuestPauseDecisionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Obx(() {
                  if (controller.isLoading.value && controller.request.value == null) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.volt));
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
                  return Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221C0C),
                        borderRadius: AppRadii.sheetRadius,
                        border: Border.all(color: const Color(0xFF4A3B12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MODE MALADE',
                            style: AppTypography.labelMd.copyWith(
                              fontSize: 11.5,
                              color: AppColors.amber,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Un allié demande une pause',
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "En l'approuvant, les pointages sont suspendus et "
                            "l'échéance sera repoussée d'autant à la reprise.",
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: Color(0xFFD8CFA8),
                            ),
                          ),
                          if (request.description != null &&
                              request.description!.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: AppRadii.interactiveRadius,
                              ),
                              child: Text(
                                '« ${request.description} »',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.primary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (request.status == QuestPauseRequestStatus.pending)
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'REFUSER',
                                    variant: AppButtonVariant.danger,
                                    loading: controller.isDeciding.value,
                                    onPressed: controller.isDeciding.value
                                        ? null
                                        : () async {
                                            final ok = await controller.decide(approve: false);
                                            if (ok) {
                                              await Get.find<QuestListController>()
                                                  .loadPendingPauseRequests();
                                              Get.back();
                                            }
                                          },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppButton(
                                    label: 'APPROUVER',
                                    variant: AppButtonVariant.amber,
                                    loading: controller.isDeciding.value,
                                    onPressed: controller.isDeciding.value
                                        ? null
                                        : () async {
                                            final ok = await controller.decide(approve: true);
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
                              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
