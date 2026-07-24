import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/widgets/quest_summary_card.dart';

/// "History" tab — completed, failed, and cancelled quests.
class HistoryView extends GetView<QuestListController> {
  const HistoryView({super.key});

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HISTORIQUE',
                  style: AppTypography.titleLg.copyWith(color: AppColors.primary),
                ),
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
            final historyQuests = controller.historyQuests;
            if (historyQuests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Aucun historique pour l\'instant. Les quêtes complétées et échouées apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  for (final quest in historyQuests) ...[
                    QuestSummaryCard(quest: quest),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
