import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/quest_deletion_vote_controller.dart';
import '../models/quest_deletion_request.dart';

class QuestDeletionVoteView extends GetView<QuestDeletionVoteController> {
  const QuestDeletionVoteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.isLoading.value && controller.request.value == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
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
                  'DEMANDE DE SUPPRESSION',
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 12),
                Text(
                  "Le propriétaire souhaite supprimer cette quête. Votre approbation est requise "
                  "à l'unanimité avec les autres alliés — un seul refus renvoie la mise aux alliés.",
                  style: AppTypography.bodyMd.copyWith(color: AppColors.primary, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '${request.votes.approved}/${request.votes.total} alliés ont approuvé',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 32),
                if (request.status == QuestDeletionRequestStatus.pending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.isVoting.value
                              ? null
                              : () async {
                                  final ok = await controller.vote(approve: false);
                                  if (ok) Get.back();
                                },
                          child: const Text('REJETER'),
                        ),
                      ),
                      const SizedBox(width: 16),
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
            );
          }),
        ),
      ),
    );
  }
}
