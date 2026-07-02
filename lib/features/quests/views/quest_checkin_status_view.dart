import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../../shell/controllers/shell_controller.dart';
import '../controllers/quest_list_controller.dart';

/// Shown right after a successful check-in submission — a terminal
/// confirmation state, not a tab (reached only via [QuestValidationView]).
class QuestCheckinStatusView extends GetView<QuestListController> {
  const QuestCheckinStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final String questId = Get.arguments as String;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: GlassChrome(
              safeAreaTop: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    ),
                    Text(
                      'AXIOM',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 20,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Get.offAllNamed(AppRoutes.home);
                        Get.find<ShellController>().changeTab(2);
                      },
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.surfaceContainerHighest,
                        child: Icon(Icons.person, size: 18, color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final quest = controller.findById(questId);
              if (quest == null) {
                return Center(
                  child: Text(
                    'Quête introuvable.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryFixed.withValues(alpha: 0.2),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryFixed.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryFixed,
                                    size: 48,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                            Text(
                              "TERMINÉ POUR AUJOURD'HUI",
                              textAlign: TextAlign.center,
                              style: AppTypography.displayLg.copyWith(
                                color: AppColors.primary,
                                fontSize: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Preuve soumise et en attente de validation par vos alliés.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.primaryFixed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'SÉRIE : ${quest.streakDays} JOURS',
                              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: SegmentedProgress(ratio: quest.progressRatio, height: 12),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              '"La précision est le fondement de la cohérence."',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.outline.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'TABLEAU DE BORD',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Get.offAllNamed(AppRoutes.home),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
