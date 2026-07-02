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
import '../../shell/controllers/shell_controller.dart';
import '../controllers/quest_list_controller.dart';
import '../models/quest_ally.dart';
import '../models/quest_model.dart';

class QuestDetailView extends GetView<QuestListController> {
  const QuestDetailView({super.key});

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
                        Get.back();
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
              return _QuestDetailBody(quest: quest);
            }),
          ),
        ],
      ),
    );
  }
}

class _QuestDetailBody extends GetView<QuestListController> {
  const _QuestDetailBody({required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context) {
    final velocityPercent = (quest.progressRatio * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUÊTE ACTIVE',
            style: AppTypography.labelMd.copyWith(color: AppColors.emerald),
          ),
          const SizedBox(height: 8),
          Text(
            quest.title,
            style: AppTypography.displayLg.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'VÉLOCITÉ ACTUELLE',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              Text(
                '$velocityPercent%',
                style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedProgress(ratio: quest.progressRatio, height: 24),
          const SizedBox(height: 32),
          AppButton(
            label: 'VALIDER AVEC PREUVE',
            leadingIcon: Icons.task_alt,
            onPressed: quest.isComplete
                ? null
                : () => Get.toNamed(AppRoutes.questValidation, arguments: quest.id),
          ),
          const SizedBox(height: 40),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BentoCard(
                    icon: Icons.payments,
                    iconColor: AppColors.emerald,
                    title: 'LES ENJEUX',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.stakeAmount != null
                              ? formatXof(quest.stakeAmount!)
                              : '—',
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'EN RISQUE',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        if (quest.stakeConsequence.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            quest.stakeConsequence,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _BentoCard(
                    icon: Icons.group,
                    iconColor: AppColors.outline,
                    title: 'LE PACTE',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AllyAvatarStack(allies: quest.allies),
                        const SizedBox(height: 12),
                        Text(
                          '${quest.allies.length} allié(s) actif(s) dans cette boucle de synchronisation.',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          if (quest.allies.isNotEmpty) ...[
            _SectionCard(
              icon: Icons.verified_user,
              title: 'STATUT DES ALLIÉS',
              child: Column(
                children: [
                  for (final ally in quest.allies) ...[
                    _AllyStatusRow(ally: ally),
                    if (ally != quest.allies.last) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
          _SectionCard(
            icon: Icons.calendar_month,
            title: 'REGISTRE D\'INTÉGRITÉ',
            trailing: Text(
              'SÉRIE : ${quest.streakDays} JOURS',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.emerald,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _ActivityHeatmap(activityLog: quest.activityLog),
          ),
          const SizedBox(height: 40),
          Text(
            'PARAMÈTRES OPÉRATIONNELS',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          _MetadataRow(label: 'Méthode de vérification', value: quest.verificationMethod),
          const SizedBox(height: 8),
          _MetadataRow(label: 'Échéance', value: quest.deadline),
          const SizedBox(height: 8),
          _MetadataRow(
            label: 'Période de grâce',
            value: quest.gracePeriod,
            valueColor: AppColors.emerald,
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AllyAvatarStack extends StatelessWidget {
  const _AllyAvatarStack({required this.allies});

  final List<QuestAlly> allies;

  @override
  Widget build(BuildContext context) {
    const shown = 3;
    final visible = allies.take(shown).toList();
    final overflow = allies.length - visible.length;
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 26.0,
              child: _AllyInitialAvatar(name: visible[i].name),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * 26.0,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceContainerLow, width: 2),
                ),
                child: Text(
                  '+$overflow',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllyInitialAvatar extends StatelessWidget {
  const _AllyInitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceContainerLow, width: 2),
      ),
      child: Text(
        initial,
        style: AppTypography.labelMd.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _AllyStatusRow extends StatelessWidget {
  const _AllyStatusRow({required this.ally});

  final QuestAlly ally;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _AllyInitialAvatar(name: ally.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ally.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ally.approved
                  ? AppColors.emerald.withValues(alpha: 0.1)
                  : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ally.approved ? Icons.check_circle : Icons.schedule,
                  size: 14,
                  color: ally.approved ? AppColors.emerald : AppColors.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  ally.approved ? 'APPROUVÉ' : 'EN ATTENTE',
                  style: AppTypography.labelMd.copyWith(
                    color: ally.approved ? AppColors.emerald : AppColors.outline,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.activityLog});

  final List<bool> activityLog;
  static const _dayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _dayLabels.length + activityLog.length,
          itemBuilder: (context, index) {
            if (index < _dayLabels.length) {
              return Center(
                child: Text(
                  _dayLabels[index],
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                    fontSize: 10,
                  ),
                ),
              );
            }
            final dayIndex = index - _dayLabels.length;
            final isToday = dayIndex == activityLog.length - 1;
            final filled = activityLog[dayIndex];
            return Container(
              decoration: BoxDecoration(
                color: filled ? AppColors.emerald : AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
                border: isToday ? Border.all(color: AppColors.emerald) : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.outlineVariant, height: 1),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LegendDot(color: AppColors.emerald, label: 'REMPLI'),
            _LegendDot(color: AppColors.surfaceContainerHighest, label: 'MANQUÉ'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
      ],
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMd.copyWith(
                color: valueColor ?? AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
