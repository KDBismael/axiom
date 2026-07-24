import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally.dart';
import '../controllers/quest_list_controller.dart';
import '../models/check_in_model.dart';
import '../models/quest_deletion_request.dart';
import '../models/quest_model.dart';

class QuestDetailView extends StatefulWidget {
  const QuestDetailView({super.key});

  @override
  State<QuestDetailView> createState() => _QuestDetailViewState();
}

class _QuestDetailViewState extends State<QuestDetailView> {
  late final String questId;
  final controller = Get.find<QuestListController>();

  @override
  void initState() {
    super.initState();
    questId = Get.arguments as String;
    controller.refreshQuest(questId);
    controller.loadDeletionRequest(questId);
  }

  @override
  Widget build(BuildContext context) {
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
                Spacer(),
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
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
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

  static const _statusLabels = {
    QuestStatus.pendingPayment: 'EN ATTENTE DE PAIEMENT',
    QuestStatus.active: 'QUÊTE ACTIVE',
    QuestStatus.completed: 'QUÊTE RÉUSSIE',
    QuestStatus.failed: 'QUÊTE ÉCHOUÉE',
  };

  @override
  Widget build(BuildContext context) {
    final velocityPercent = (quest.progress * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusLabels[quest.status] ?? '',
            style: AppTypography.labelMd.copyWith(color: AppColors.emerald),
          ),
          const SizedBox(height: 8),
          Text(
            quest.title,
            style: AppTypography.displayLg.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            quest.description,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
          if (!quest.isFinished) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _editDescription(context, quest),
              child: Text(
                'MODIFIER LA DESCRIPTION',
                style: AppTypography.labelMd.copyWith(color: AppColors.emerald),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Obx(() {
            final request = controller.deletionRequests[quest.id];
            if (request == null ||
                request.status != QuestDeletionRequestStatus.pending) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _PendingDeletionBanner(quest: quest, request: request),
            );
          }),
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
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedProgress(ratio: quest.progress, height: 24),
          const SizedBox(height: 32),
          Obx(() {
            final isPendingDeletion =
                controller.deletionRequests[quest.id]?.status ==
                QuestDeletionRequestStatus.pending;
            if (quest.isPendingPayment) {
              return AppButton(
                label: 'PAYER LA MISE',
                leadingIcon: Icons.payments,
                onPressed: () =>
                    Get.toNamed(AppRoutes.questPayment, arguments: quest.id),
              );
            }
            return AppButton(
              label: 'VALIDER AVEC PREUVE',
              leadingIcon: Icons.task_alt,
              onPressed: quest.isActive && !isPendingDeletion
                  ? () => Get.toNamed(
                      AppRoutes.questValidation,
                      arguments: quest.id,
                    )
                  : null,
            );
          }),
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
                          quest.stakeAmountXof != null
                              ? formatXof(quest.stakeAmountXof!)
                              : 'Aucun enjeu',
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        if (quest.fundsDistribution != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            quest.fundsDistribution == FundsDistribution.allies
                                ? "En cas d'échec, reversé aux alliés."
                                : "En cas d'échec, reversé à une association caritative.",
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
                    icon: Icons.shield_moon,
                    iconColor: AppColors.outline,
                    title: 'NIVEAU DE RISQUE',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _riskLabels[quest.riskLevel] ?? '',
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          quest.requiresProof
                              ? 'Preuve requise'
                              : 'Sur l\'honneur',
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
          _SectionCard(
            icon: Icons.calendar_month,
            title: "REGISTRE D'INTÉGRITÉ",
            trailing: Text(
              'SÉRIE : ${quest.streakDays} JOURS',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.emerald,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _CheckInHistory(questId: quest.id),
          ),
          const SizedBox(height: 40),
          Text(
            'PARAMÈTRES OPÉRATIONNELS',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          _MetadataRow(
            label: 'Fréquence',
            value: quest.frequency == QuestFrequency.daily
                ? 'Quotidienne'
                : 'Hebdomadaire',
          ),
          const SizedBox(height: 8),
          _MetadataRow(
            label: 'Seuil de réussite',
            value: '${quest.successThresholdPercent}%',
          ),
          const SizedBox(height: 8),
          _MetadataRow(label: 'Échéance', value: _formatDate(quest.deadline)),
          const SizedBox(height: 8),
          _MetadataRow(
            label: 'Période de grâce',
            value: '${quest.gracePeriodDays} jour(s)',
            valueColor: AppColors.emerald,
          ),
          const SizedBox(height: 40),
          _SectionCard(
            icon: Icons.groups,
            title: 'ALLIÉS DE LA QUÊTE',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (quest.allies.isEmpty)
                  Text(
                    'Aucun allié sur cette quête pour le moment.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
                  )
                else
                  for (final ally in quest.allies) ...[
                    _MetadataRow(
                      label: '${ally.firstName} ${ally.lastName}',
                      value: switch (ally.status) {
                        QuestAllyStatus.accepted => 'Accepté',
                        QuestAllyStatus.pending => 'En attente',
                        QuestAllyStatus.declined => 'Refusé',
                      },
                      valueColor: ally.status == QuestAllyStatus.accepted
                          ? AppColors.emerald
                          : null,
                    ),
                    if (ally != quest.allies.last) const SizedBox(height: 8),
                  ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _inviteAllies(context, quest),
                  child: Text(
                    'INVITER UN ALLIÉ',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!quest.isFinished) ...[
            const SizedBox(height: 40),
            OutlinedButton(
              onPressed: () => _confirmDeletion(context, quest),
              child: Text(
                'SUPPRIMER LA QUÊTE',
                style: AppTypography.labelMd.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _inviteAllies(BuildContext context, QuestModel quest) {
    final allies = Get.find<AlliesController>();
    final alreadyOnQuest = quest.allies.map((a) => a.userId).toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      builder: (context) => _InviteAlliesSheet(
        questId: quest.id,
        hasAnyAllies: allies.allies.isNotEmpty,
        candidates: allies.allies
            .where((a) => !alreadyOnQuest.contains(a.id))
            .toList(),
        controller: controller,
      ),
    );
  }

  void _editDescription(BuildContext context, QuestModel quest) {
    final textController = TextEditingController(text: quest.description);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLow,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODIFIER LA DESCRIPTION',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'ENREGISTRER',
                  onPressed: () async {
                    final ok = await controller.updateDescription(
                      quest.id,
                      textController.text.trim(),
                    );
                    if (ok && context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletion(BuildContext context, QuestModel quest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: const Text('Supprimer cette quête ?'),
        content: Text(
          quest.allies.any((a) => a.status == QuestAllyStatus.accepted)
              ? "Vos alliés devront approuver cette suppression à l'unanimité."
              : quest.hasStake
              ? 'Votre mise vous sera remboursée immédiatement.'
              : 'Cette action est immédiate et irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final outcome = await controller.requestDeletion(quest.id);
    if (outcome == null) return;
    if (outcome.deleted || outcome.cancelled) {
      Get.back();
    }
  }

  static const _riskLabels = {
    QuestRiskLevel.low: 'FAIBLE',
    QuestRiskLevel.medium: 'MODÉRÉ',
    QuestRiskLevel.high: 'ÉLEVÉ',
  };

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _InviteAlliesSheet extends StatefulWidget {
  const _InviteAlliesSheet({
    required this.questId,
    required this.hasAnyAllies,
    required this.candidates,
    required this.controller,
  });

  final String questId;

  /// Whether the user has any accepted global allies at all — distinguishes
  /// "you have no friends yet" from "all your friends are already invited".
  final bool hasAnyAllies;
  final List<Ally> candidates;
  final QuestListController controller;

  @override
  State<_InviteAlliesSheet> createState() => _InviteAlliesSheetState();
}

class _InviteAlliesSheetState extends State<_InviteAlliesSheet> {
  final _selectedIds = <String>{};
  bool _isSending = false;

  Future<void> _send() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isSending = true);
    final ok = await widget.controller.inviteAllies(
      widget.questId,
      _selectedIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INVITER UN ALLIÉ SUR CETTE QUÊTE',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            if (!widget.hasAnyAllies) ...[
              Text(
                "Vous n'avez pas encore d'alliés. Invitez d'abord des amis sur Axiom, "
                "puis revenez ici pour les ajouter à cette quête.",
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'INVITER DES AMIS',
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.toNamed(AppRoutes.inviteFriends);
                },
              ),
            ] else if (widget.candidates.isEmpty)
              Text(
                'Tous vos alliés sont déjà invités sur cette quête.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              )
            else
              for (final ally in widget.candidates)
                CheckboxListTile(
                  value: _selectedIds.contains(ally.id),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedIds.add(ally.id);
                    } else {
                      _selectedIds.remove(ally.id);
                    }
                  }),
                  title: Text(
                    '${ally.firstName} ${ally.lastName}',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  activeColor: AppColors.emerald,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            if (widget.candidates.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'ENVOYER LES INVITATIONS',
                loading: _isSending,
                onPressed: _selectedIds.isEmpty || _isSending ? null : _send,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingDeletionBanner extends StatelessWidget {
  const _PendingDeletionBanner({required this.quest, required this.request});

  final QuestModel quest;
  final QuestDeletionRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: const Border(
          left: BorderSide(color: AppColors.error, width: 4),
        ),
      ),
      child: Text(
        'Suppression en attente d\'approbation '
        '(${request.votes.approved}/${request.votes.total} alliés)',
        style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
      ),
    );
  }
}

/// Fetches and renders the quest's real check-in history — replaces the old
/// static `activityLog` heatmap now that check-ins are server-tracked.
class _CheckInHistory extends StatelessWidget {
  const _CheckInHistory({required this.questId});

  final String questId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CheckIn>>(
      future: Get.find<QuestListController>().fetchCheckIns(questId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
          );
        }
        final checkIns = snapshot.data!;
        if (checkIns.isEmpty) {
          return Text(
            'Aucun check-in pour le moment.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          );
        }
        return Column(
          children: [
            for (final checkIn in checkIns.reversed) ...[
              _CheckInRow(checkIn: checkIn),
              if (checkIn != checkIns.first) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({required this.checkIn});

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final latestEvidence = checkIn.evidence.isNotEmpty
        ? checkIn.evidence.last
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          Icon(
            latestEvidence == null
                ? Icons.check_circle
                : switch (latestEvidence.status) {
                    EvidenceStatus.approved => Icons.check_circle,
                    EvidenceStatus.rejected => Icons.cancel,
                    EvidenceStatus.pending => Icons.schedule,
                  },
            size: 16,
            color: latestEvidence == null
                ? AppColors.emerald
                : switch (latestEvidence.status) {
                    EvidenceStatus.approved => AppColors.emerald,
                    EvidenceStatus.rejected => AppColors.error,
                    EvidenceStatus.pending => AppColors.outline,
                  },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${checkIn.date.day.toString().padLeft(2, '0')}/${checkIn.date.month.toString().padLeft(2, '0')}/${checkIn.date.year}',
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          if (latestEvidence != null)
            Text(
              switch (latestEvidence.status) {
                EvidenceStatus.approved => 'PREUVE APPROUVÉE',
                EvidenceStatus.rejected => 'PREUVE REJETÉE',
                EvidenceStatus.pending => 'PREUVE EN ATTENTE',
              },
              style: AppTypography.labelMd.copyWith(
                color: switch (latestEvidence.status) {
                  EvidenceStatus.approved => AppColors.emerald,
                  EvidenceStatus.rejected => AppColors.error,
                  EvidenceStatus.pending => AppColors.outline,
                },
                fontSize: 10,
              ),
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
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
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
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
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

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          Spacer(),
          Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMd.copyWith(
              color: valueColor ?? AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
