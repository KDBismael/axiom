import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../controllers/quest_list_controller.dart';
import '../models/quest_model.dart';
import '../utils/period_progress.dart';

/// Shown right after a successful check-in submission — a terminal
/// confirmation state, not a tab (reached only via [QuestValidationView]).
class QuestCheckinStatusView extends StatefulWidget {
  const QuestCheckinStatusView({super.key});

  @override
  State<QuestCheckinStatusView> createState() => _QuestCheckinStatusViewState();
}

class _QuestCheckinStatusViewState extends State<QuestCheckinStatusView> {
  int _currentPeriodCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final questId = Get.arguments as String;
    final controller = Get.find<QuestListController>();
    final quest = controller.findById(questId);
    if (quest == null) {
      setState(() => _loading = false);
      return;
    }
    final checkIns = await controller.fetchCheckIns(questId);
    setState(() {
      _currentPeriodCount = countCheckInsInCurrentPeriod(
        checkIns,
        quest.frequency,
        DateTime.now(),
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestListController>();
    final String questId = Get.arguments as String;

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
              final periodComplete =
                  _loading || _currentPeriodCount >= quest.targetPerPeriod;
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                              periodComplete
                                  ? "TERMINÉ POUR AUJOURD'HUI"
                                  : 'POINTAGE $_currentPeriodCount/${quest.targetPerPeriod}',
                              textAlign: TextAlign.center,
                              style: AppTypography.displayLg.copyWith(
                                color: AppColors.primary,
                                fontSize: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              periodComplete
                                  ? 'Preuve soumise et en attente de validation par vos alliés.'
                                  : "Encore ${quest.targetPerPeriod - _currentPeriodCount} pointage"
                                      "${quest.targetPerPeriod - _currentPeriodCount > 1 ? 's' : ''} "
                                      "${quest.frequency == QuestFrequency.daily ? "aujourd'hui" : 'cette semaine'}.",
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
                              child: SegmentedProgress(ratio: quest.progress, height: 12),
                            ),
                            if (!_loading && quest.targetPerPeriod > 1) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: SegmentedProgress(
                                  ratio: _currentPeriodCount / quest.targetPerPeriod,
                                  height: 6,
                                ),
                              ),
                            ],
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
