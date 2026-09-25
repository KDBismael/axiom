import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/quest_deletion_vote_controller.dart';
import '../models/quest_deletion_request.dart';

/// The INBOX approve/reject card pattern, applied to a deletion vote — no
/// literal mockup for this screen, so it reuses the mockup's own request
/// card structure (summary + detail + REJETER/APPROUVER).
class QuestDeletionVoteView extends GetView<QuestDeletionVoteController> {
  const QuestDeletionVoteView({super.key});

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
                        color: const Color(0xFF220F10),
                        borderRadius: AppRadii.sheetRadius,
                        border: Border.all(color: const Color(0xFF4A2525)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VOTE DE SUPPRESSION',
                            style: AppTypography.labelMd.copyWith(
                              fontSize: 11.5,
                              color: AppColors.errorSoft,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Un allié veut supprimer cette quête',
                            style: TextStyle(
                              fontFamily: 'Unbounded',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: List.generate(request.votes.total, (i) {
                              final filled = i < request.votes.approved;
                              return Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsets.only(right: i == request.votes.total - 1 ? 0 : 4),
                                  decoration: BoxDecoration(
                                    color: filled ? AppColors.errorSoft : AppColors.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unanimité requise. Un seul refus fait échouer la quête et '
                            'partage la mise entre les alliés.',
                            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.errorSoft.withValues(alpha: 0.85)),
                          ),
                          const SizedBox(height: 20),
                          if (request.status == QuestDeletionRequestStatus.pending)
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'REJETER',
                                    variant: AppButtonVariant.danger,
                                    loading: controller.isVoting.value,
                                    onPressed: controller.isVoting.value
                                        ? null
                                        : () async {
                                            final ok = await controller.vote(approve: false);
                                            if (ok) Get.back();
                                          },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: AppButton(
                                    label: 'APPROUVER',
                                    loading: controller.isVoting.value,
                                    onPressed: controller.isVoting.value
                                        ? null
                                        : () async {
                                            final ok = await controller.vote(approve: true);
                                            if (ok) Get.back();
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
