import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/french_date.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../../quests/utils/quest_kind.dart';

enum _ResultFilter { all, completed, failed, cancelled }

const _resultLabels = {
  _ResultFilter.all: 'Toutes',
  _ResultFilter.completed: 'Réussies',
  _ResultFilter.failed: 'Échouées',
  _ResultFilter.cancelled: 'Annulées',
};

enum _SortOrder { newest, oldest }

/// "History" tab — completed, failed, and cancelled quests.
class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final controller = Get.find<QuestListController>();
  _ResultFilter _resultFilter = _ResultFilter.all;
  QuestKind? _typeFilter;
  bool _stakeOnly = false;
  _SortOrder _sort = _SortOrder.newest;

  bool get _isFiltered =>
      _resultFilter != _ResultFilter.all || _typeFilter != null || _stakeOnly;

  void _reset() {
    setState(() {
      _resultFilter = _ResultFilter.all;
      _typeFilter = null;
      _stakeOnly = false;
    });
  }

  void _cycleSort() {
    setState(() {
      _sort = _sort == _SortOrder.newest
          ? _SortOrder.oldest
          : _SortOrder.newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value && controller.quests.isEmpty) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 1));
        }
        final myId = Get.find<AuthController>().user.value?.id;
        final historyQuests = controller.historyQuests;
        if (historyQuests.isEmpty) {
          return _buildScroll(
            children: [
              _Header(),
              const SizedBox(height: 40),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Aucun historique pour l'instant. Les quêtes complétées et "
                    'échouées apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final counts = {
          for (final s in [
            QuestStatus.completed,
            QuestStatus.failed,
            QuestStatus.cancelled,
          ])
            s: historyQuests.where((q) => q.status == s).length,
        };

        var filtered = historyQuests.where((q) {
          if (_resultFilter == _ResultFilter.completed &&
              q.status != QuestStatus.completed) {
            return false;
          }
          if (_resultFilter == _ResultFilter.failed &&
              q.status != QuestStatus.failed) {
            return false;
          }
          if (_resultFilter == _ResultFilter.cancelled &&
              q.status != QuestStatus.cancelled) {
            return false;
          }
          if (_typeFilter != null && questKindFor(q, myId) != _typeFilter) {
            return false;
          }
          if (_stakeOnly && !q.hasStake) return false;
          return true;
        }).toList();
        filtered.sort(
          (a, b) => _sort == _SortOrder.newest
              ? b.deadline.compareTo(a.deadline)
              : a.deadline.compareTo(b.deadline),
        );

        return _buildScroll(
          children: [
            _Header(),
            const SizedBox(height: 16),
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
                    label:
                        'annulée${(counts[QuestStatus.cancelled] ?? 0) > 1 ? 's' : ''}',
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
                  for (final f in _ResultFilter.values) ...[
                    _FilterChip(
                      label: _resultLabels[f]!,
                      selected: _resultFilter == f,
                      onTap: () => setState(() => _resultFilter = f),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TypeChip(
                    label: 'TOUS LES TYPES',
                    selected: _typeFilter == null,
                    onTap: () => setState(() => _typeFilter = null),
                  ),
                  const SizedBox(width: 8),
                  for (final k in QuestKind.values) ...[
                    _TypeChip(
                      label: questKindLabels[k]!,
                      selected: _typeFilter == k,
                      onTap: () => setState(() => _typeFilter = k),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _stakeOnly = !_stakeOnly),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                    decoration: BoxDecoration(
                      color: _stakeOnly
                          ? AppColors.voltTint()
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _stakeOnly
                            ? AppColors.volt
                            : AppColors.outlineVariantStrong,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _stakeOnly
                                ? AppColors.volt
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: _stakeOnly
                                  ? AppColors.volt
                                  : AppColors.outlineVariantStrong,
                              width: 1.5,
                            ),
                          ),
                          child: _stakeOnly
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: AppColors.onPrimary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avec enjeu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _stakeOnly
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _cycleSort,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outlineVariantStrong),
                    ),
                    child: Text(
                      'Trier : ${_sort == _SortOrder.newest ? "Plus récent" : "Plus ancien"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD8D8DE),
                      ),
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
                  '${filtered.length} dossier${filtered.length > 1 ? 's' : ''}'
                      .toUpperCase(),
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 11,
                    color: AppColors.outlineFaint,
                  ),
                ),
                if (_isFiltered)
                  GestureDetector(
                    onTap: _reset,
                    child: Text(
                      'RÉINITIALISER',
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 11,
                        color: AppColors.volt,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.sheetRadius,
                  border: Border.all(
                    color: AppColors.outlineVariantStrong,
                    style: BorderStyle.solid,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Aucun dossier ne correspond à ces filtres.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outlineMuted,
                  ),
                ),
              )
            else
              for (final quest in filtered) ...[
                _HistoryQuestCard(quest: quest),
                const SizedBox(height: 16),
              ],
          ],
        );
      }),
    );
  }

  Widget _buildScroll({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORIQUE',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outlineMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dossiers clos',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

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
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
          color: selected ? AppColors.voltTint() : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? AppColors.volt : AppColors.outlineVariantStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.volt : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.voltTint() : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.volt : AppColors.outlineVariantStrong,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: 11,
            letterSpacing: 0.1 * 11,
            color: selected ? AppColors.volt : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _HistoryQuestCard extends StatelessWidget {
  const _HistoryQuestCard({required this.quest});

  final QuestModel quest;

  static const _resultLabel = {
    QuestStatus.completed: 'RÉUSSIE',
    QuestStatus.failed: 'ÉCHOUÉE',
    QuestStatus.cancelled: 'ANNULÉE',
  };

  static const _resultColor = {
    QuestStatus.completed: AppColors.volt,
    QuestStatus.failed: AppColors.error,
    QuestStatus.cancelled: AppColors.outlineMuted,
  };

  String _meta() {
    final expected = expectedQuestPeriods(quest.frequency, quest.durationDays);
    final done = (quest.progress * expected).round();
    final unit = quest.frequency == QuestFrequency.daily ? 'jours' : 'semaines';
    final progressTxt = '$done/$expected $unit';
    if (!quest.hasStake || quest.stakeAmountXof == null) {
      return '$progressTxt · sans enjeu';
    }
    final amount = formatXof(quest.stakeAmountXof!);
    if (quest.status == QuestStatus.completed) {
      return '$progressTxt · $amount remboursés';
    }
    final toCharity = quest.fundsDistribution == FundsDistribution.charity;
    return '$progressTxt · $amount ${toCharity ? 'donnés à une association' : 'partagés entre alliés'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.questDetail, arguments: quest.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.structuralRadius,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  formatFrDateRange(quest.startDate, quest.deadline),
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 11,
                    color: AppColors.outlineMuted,
                  ),
                ),
                Transform.rotate(
                  angle: -0.035,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _resultColor[quest.status]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _resultLabel[quest.status] ?? '',
                      style: TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        letterSpacing: 0.08 * 10.5,
                        color: _resultColor[quest.status],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quest.title,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _meta(),
              style: const TextStyle(fontSize: 13, color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}
