import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../../quests/widgets/quest_summary_card.dart';

enum _HistoryFilter { all, completed, failed, cancelled }

/// "History" tab — completed, failed, and cancelled quests.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final controller = Get.find<QuestListController>();
  _HistoryFilter _filter = _HistoryFilter.all;

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
                  style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.quests.isEmpty) {
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
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
              );
            }
            final counts = {
              for (final s in [QuestStatus.completed, QuestStatus.failed, QuestStatus.cancelled])
                s: historyQuests.where((q) => q.status == s).length,
            };
            final filtered = switch (_filter) {
              _HistoryFilter.all => historyQuests,
              _HistoryFilter.completed =>
                historyQuests.where((q) => q.status == QuestStatus.completed).toList(),
              _HistoryFilter.failed =>
                historyQuests.where((q) => q.status == QuestStatus.failed).toList(),
              _HistoryFilter.cancelled =>
                historyQuests.where((q) => q.status == QuestStatus.cancelled).toList(),
            };
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: counts[QuestStatus.completed] ?? 0,
                          label: 'réussies',
                          color: AppColors.volt,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          value: counts[QuestStatus.failed] ?? 0,
                          label: 'échouées',
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatTile(
                          value: counts[QuestStatus.cancelled] ?? 0,
                          label: 'annulées',
                          color: AppColors.outlineMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _HistoryFilter.values) ...[
                          _FilterChip(
                            label: switch (f) {
                              _HistoryFilter.all => 'Toutes',
                              _HistoryFilter.completed => 'Réussies',
                              _HistoryFilter.failed => 'Échouées',
                              _HistoryFilter.cancelled => 'Annulées',
                            },
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final quest in filtered) ...[
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w800, fontSize: 22, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.outline, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariantStrong),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.onPrimary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}
