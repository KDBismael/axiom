import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../models/quest_model.dart';

/// Quest card used on the dashboard (active quests) and the History tab
/// (finished quests) — tapping it opens the quest detail screen.
class QuestSummaryCard extends StatelessWidget {
  const QuestSummaryCard({super.key, required this.quest});

  final QuestModel quest;

  static const _statusLabels = {
    QuestStatus.completed: 'RÉUSSIE',
    QuestStatus.failed: 'ÉCHOUÉE',
    QuestStatus.cancelled: 'ANNULÉE',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.questDetail, arguments: quest.id),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: AppRadii.structuralRadius,
              border: Border.all(
                color: quest.isPendingPayment
                    ? AppColors.volt.withValues(alpha: 0.2)
                    : AppColors.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: const TextStyle(
                              fontFamily: 'Unbounded',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              height: 1.2,
                              color: AppColors.primary,
                            ),
                          ),
                          if (quest.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              quest.description,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.outline,
                              ),
                            ),
                          ],
                          if (quest.streakDays > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.rotate(
                                  angle: 0.7853981633974483,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: AppColors.ember,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${quest.streakDays}',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  quest.streakDays > 1 ? 'jours' : 'jour',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.outline,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (quest.stakeAmountXof != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.outlineVariant),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'ENJEU ${formatXof(quest.stakeAmountXof!)}',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (quest.isPendingPayment)
                  Text(
                    'EN ATTENTE DE PAIEMENT',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  )
                else if (_statusLabels.containsKey(quest.status))
                  Text(
                    _statusLabels[quest.status]!,
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROGRESSION',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${(quest.progress * 100).round()}%',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SegmentedProgress(ratio: quest.progress),
                ],
              ],
            ),
          ),
          if (quest.isPendingPayment)
            Positioned(
              top: -12,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_top,
                      size: 12,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'EN ATTENTE DE PAIEMENT',
                      style: AppTypography.labelMd.copyWith(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
