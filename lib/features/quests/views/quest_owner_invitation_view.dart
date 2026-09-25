import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/quest_owner_invitation_controller.dart';
import '../controllers/quest_list_controller.dart';
import '../models/quest_model.dart';

class QuestOwnerInvitationView extends GetView<QuestOwnerInvitationController> {
  const QuestOwnerInvitationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value &&
              controller.invitation.value == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.volt),
            );
          }
          final invitation = controller.invitation.value;
          if (invitation == null) {
            return Center(
              child: Text(
                controller.errorMessage.value ?? 'Invitation introuvable.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      'NDELI',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ON VOUS OFFRE UNE QUÊTE',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                      if (invitation.creatorName.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              size: 18,
                              color: AppColors.volt,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Proposée par ${invitation.creatorName}',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        invitation.title,
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        invitation.description,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.outline,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: AppRadii.structuralRadius,
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.volt,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Text(
                          "En acceptant, cette quête devient la vôtre : vous vous "
                          "engagez à réaliser l'habitude vous-même. "
                          "${invitation.creatorName.isNotEmpty ? invitation.creatorName : 'La personne qui vous l\'offre'} "
                          "deviendra votre allié de responsabilité.",
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoRow(
                        label: 'Fréquence',
                        value: invitation.frequency == QuestFrequency.daily
                            ? 'Quotidien'
                            : 'Hebdomadaire',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Durée',
                        value: '${invitation.durationDays} jours',
                      ),
                      if (invitation.hasStake) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Enjeu déjà financé',
                          value: formatXof(invitation.stakeAmountXof ?? 0),
                          valueColor: AppColors.volt,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Obx(() {
                final error = controller.errorMessage.value;
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    error,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                );
              }),
              if (invitation.status != QuestOwnerInvitationStatus.pending)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadii.structuralRadius,
                      border: Border.all(
                        color:
                            invitation.status ==
                                QuestOwnerInvitationStatus.accepted
                            ? AppColors.volt.withValues(alpha: 0.3)
                            : AppColors.outlineVariant15,
                      ),
                    ),
                    child: Text(
                      invitation.status == QuestOwnerInvitationStatus.accepted
                          ? 'Vous avez accepté cette quête.'
                          : 'Vous avez refusé cette offre.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color:
                            invitation.status ==
                                QuestOwnerInvitationStatus.accepted
                            ? AppColors.volt
                            : AppColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'REFUSER',
                          variant: AppButtonVariant.danger,
                          onPressed: controller.isResponding.value
                              ? null
                              : () async {
                                  final ok = await controller.respond(
                                    accept: false,
                                  );
                                  if (ok) {
                                    await Get.find<QuestListController>()
                                        .loadPendingOwnerInvitations();
                                    Get.back();
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          label: 'ACCEPTER',
                          loading: controller.isResponding.value,
                          onPressed: controller.isResponding.value
                              ? null
                              : () async {
                                  final ok = await controller.respond(
                                    accept: true,
                                  );
                                  if (ok) {
                                    await Future.wait([
                                      Get.find<QuestListController>()
                                          .loadPendingOwnerInvitations(),
                                      Get.find<QuestListController>()
                                          .loadQuests(),
                                    ]);
                                    Get.back();
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodyMd.copyWith(
            color: valueColor ?? AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
