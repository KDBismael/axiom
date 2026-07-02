import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../../shell/controllers/shell_controller.dart';

/// L'onglet "Tableau de bord" — rendu à l'intérieur du shell à navigation
/// persistante de l'app (voir `MainShellView`), il possède donc son propre
/// en-tête vitré mais pas de barre de navigation basse.
class HomeView extends GetView<QuestListController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: GlassChrome(
            safeAreaTop: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AXIOM',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02 * 20,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.find<ShellController>().changeTab(2),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceContainerHighest,
                      child: Icon(Icons.person, color: AppColors.outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 1),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUT ACTUEL',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TABLEAU DE BORD',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _StatsRow(controller: controller),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'QUÊTES ACTIVES',
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${controller.quests.length} EN COURS',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final quest in controller.quests) ...[
                    _QuestDashboardCard(quest: quest),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'CRÉER UNE QUÊTE',
                    onPressed: () => Get.toNamed(AppRoutes.questCreate),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final QuestListController controller;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: _StatCard(
              background: AppColors.surfaceContainerLow,
              labelColor: AppColors.outline,
              valueColor: AppColors.primary,
              label: 'ENJEUX TOTAUX',
              value: formatXof(controller.totalStakeAmount),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: _StatCard(
              background: AppColors.primary,
              labelColor: Colors.black,
              valueColor: Colors.black,
              label: 'NIVEAU DE RISQUE',
              value: controller.riskLevel,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.background,
    required this.labelColor,
    required this.valueColor,
    required this.label,
    required this.value,
  });

  final Color background;
  final Color labelColor;
  final Color valueColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.interactiveRadius,
        border: background == AppColors.surfaceContainerLow
            ? Border.all(color: AppColors.outlineVariant15)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMd.copyWith(color: labelColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineMd.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _QuestDashboardCard extends StatelessWidget {
  const _QuestDashboardCard({required this.quest});

  final QuestModel quest;

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
              borderRadius: AppRadii.interactiveRadius,
              border: Border.all(
                color: quest.pendingValidation
                    ? AppColors.emerald.withValues(alpha: 0.2)
                    : AppColors.outlineVariant15,
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
                            style: AppTypography.headlineMd.copyWith(
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
                        ],
                      ),
                    ),
                    if (quest.stakeAmount != null)
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
                          'ENJEU ${formatXof(quest.stakeAmount!)}',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      '${quest.progress} / ${quest.total}',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedProgress(ratio: quest.progressRatio),
              ],
            ),
          ),
          if (quest.pendingValidation)
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
                      'VALIDATION EN ATTENTE',
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
