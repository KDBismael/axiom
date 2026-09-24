import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally.dart';
import '../../social/models/user_search_result.dart';
import '../controllers/quest_list_controller.dart';
import '../models/check_in_model.dart';
import '../models/focus_session_model.dart';
import '../models/quest_deletion_request.dart';
import '../models/quest_group_progress.dart';
import '../models/quest_model.dart';
import '../models/quest_pause_request.dart';

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
    controller.loadPauseRequest(questId);
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
    QuestStatus.paused: 'QUÊTE EN PAUSE',
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
          _StatusPill(status: quest.status, label: _statusLabels[quest.status] ?? ''),
          const SizedBox(height: 16),
          Text(
            quest.title,
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
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
                style: AppTypography.labelMd.copyWith(color: AppColors.volt),
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
          Obx(() {
            final pause = controller.pauseRequests[quest.id];
            if (quest.isPaused) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _PausedBanner(quest: quest, controller: controller),
              );
            }
            if (pause != null &&
                pause.status == QuestPauseRequestStatus.pending) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: _PendingPauseBanner(),
              );
            }
            return const SizedBox.shrink();
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PROGRESSION',
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
                label: 'REPRENDRE LE PAIEMENT',
                leadingIcon: Icons.payments,
                onPressed: () =>
                    Get.toNamed(AppRoutes.questPayment, arguments: quest.id),
              );
            }
            return Column(
              children: [
                AppButton(
                  label: 'VALIDER AVEC PREUVE',
                  leadingIcon: Icons.task_alt,
                  onPressed: quest.isActive && !isPendingDeletion
                      ? () => Get.toNamed(
                          AppRoutes.questValidation,
                          arguments: quest.id,
                        )
                      : null,
                ),
                if (!quest.hasStake) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'AJOUTER UN ENJEU',
                    leadingIcon: Icons.add_card,
                    variant: AppButtonVariant.secondary,
                    onPressed: quest.isActive && !isPendingDeletion
                        ? () => _addStake(context, quest)
                        : null,
                  ),
                ],
                if (quest.isActive &&
                    !isPendingDeletion &&
                    controller.pauseRequests[quest.id]?.status !=
                        QuestPauseRequestStatus.pending) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'METTRE EN PAUSE',
                    leadingIcon: Icons.sick_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _requestPause(context, quest),
                  ),
                ],
                const SizedBox(height: 12),
                // Temporarily disabled — grayed out until the timer feature
                // is ready to ship.
                AppButton(
                  label: 'MINUTEUR DE FOCUS',
                  leadingIcon: Icons.timer_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: null,
                ),
              ],
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
                    iconColor: AppColors.volt,
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
                color: AppColors.volt,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _CheckInHistory(questId: quest.id),
          ),
          const SizedBox(height: 40),
          _SectionCard(
            icon: Icons.timer_outlined,
            title: 'SESSIONS DE FOCUS',
            child: _FocusSessionHistory(questId: quest.id),
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
            label: 'Absences tolérées',
            value:
                '${toleratedMissedPeriods(frequency: quest.frequency, durationDays: quest.durationDays, successThresholdPercent: quest.successThresholdPercent)} '
                '${quest.frequency == QuestFrequency.daily ? 'jour(s)' : 'semaine(s)'}',
          ),
          const SizedBox(height: 8),
          _MetadataRow(label: 'Échéance', value: _formatDate(quest.deadline)),
          const SizedBox(height: 8),
          _MetadataRow(
            label: 'Rattrapage après échéance',
            value: '${quest.gracePeriodDays} jour(s)',
            valueColor: AppColors.volt,
          ),
          const SizedBox(height: 40),
          _SectionCard(
            icon: Icons.groups,
            title: quest.isCollective
                ? 'MEMBRES DU GROUPE'
                : 'ALLIÉS DE LA QUÊTE',
            child: quest.isCollective
                ? _GroupMembersSection(quest: quest, controller: controller)
                : Column(
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
                                ? AppColors.volt
                                : null,
                          ),
                          if (ally != quest.allies.last)
                            const SizedBox(height: 8),
                        ],
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _inviteAllies(context, quest),
                        child: Text(
                          'INVITER UN ALLIÉ',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.volt,
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
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.errorShadow),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.interactiveRadius),
              ),
              child: Text(
                'Supprimer la quête',
                style: const TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.w600, color: AppColors.errorSoft),
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
    showAppBottomSheet(
      context,
      builder: (context) => _InviteAlliesSheet(
        questId: quest.id,
        excludedUserIds: alreadyOnQuest,
        candidates: allies.allies
            .where((a) => !alreadyOnQuest.contains(a.id))
            .toList(),
        controller: controller,
      ),
    );
  }

  void _addStake(BuildContext context, QuestModel quest) {
    showAppBottomSheet(
      context,
      builder: (context) => _AddStakeSheet(quest: quest),
    );
  }

  void _requestPause(BuildContext context, QuestModel quest) {
    showAppBottomSheet(
      context,
      builder: (context) =>
          _RequestPauseSheet(quest: quest, controller: controller),
    );
  }

  void _editDescription(BuildContext context, QuestModel quest) {
    final textController = TextEditingController(text: quest.description);
    showAppBottomSheet(
      context,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.label});

  final QuestStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, border, dot) = switch (status) {
      QuestStatus.active || QuestStatus.completed => (
          const Color(0xFF1A2210),
          const Color(0xFF2F3F14),
          AppColors.volt,
        ),
      QuestStatus.failed => (const Color(0xFF220F10), const Color(0xFF4A2525), AppColors.error),
      _ => (AppColors.surfaceContainerLow, AppColors.outlineVariant, AppColors.outlineMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(color: dot, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AddStakeSheet extends StatefulWidget {
  const _AddStakeSheet({required this.quest});

  final QuestModel quest;

  @override
  State<_AddStakeSheet> createState() => _AddStakeSheetState();
}

class _AddStakeSheetState extends State<_AddStakeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  FundsDistribution? _distribution;
  String? _distributionError;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startingFromZero = !widget.quest.hasStake;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                startingFromZero ? 'DÉMARRER UN ENJEU' : 'AJOUTER UN ENJEU',
                style: AppTypography.titleLg.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                decoration: const InputDecoration(
                  labelText: 'Montant (XOF)',
                  hintText: '200',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount < 200) {
                    return 'Minimum 200 XOF';
                  }
                  return null;
                },
              ),
              if (startingFromZero) ...[
                const SizedBox(height: 20),
                Text(
                  'DISTRIBUTION DES FONDS',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 12),
                _FundsChoiceOption(
                  label: 'Partager entre mes alliés',
                  selected: _distribution == FundsDistribution.allies,
                  onTap: () => setState(() {
                    _distribution = FundsDistribution.allies;
                    _distributionError = null;
                  }),
                ),
                const SizedBox(height: 8),
                _FundsChoiceOption(
                  label: 'Donner à une association',
                  selected: _distribution == FundsDistribution.charity,
                  onTap: () => setState(() {
                    _distribution = FundsDistribution.charity;
                    _distributionError = null;
                  }),
                ),
                if (_distributionError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _distributionError!,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              AppButton(label: 'CONTINUER', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    final startingFromZero = !widget.quest.hasStake;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (startingFromZero && _distribution == null) {
      setState(
        () => _distributionError =
            "Choisissez comment les fonds seront reversés en cas d'échec",
      );
      return;
    }
    final amount = double.parse(_amountController.text.trim());
    Navigator.of(context).pop();
    Get.toNamed(
      AppRoutes.questPayment,
      arguments: {
        'questId': widget.quest.id,
        'additionalAmountXof': amount,
        if (_distribution != null) 'fundsDistribution': _distribution!.name,
      },
    );
  }
}

class _FundsChoiceOption extends StatelessWidget {
  const _FundsChoiceOption({
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
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainer,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(
            color: selected
                ? AppColors.volt
                : AppColors.outlineVariant15,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _InviteAlliesSheet extends StatefulWidget {
  const _InviteAlliesSheet({
    required this.questId,
    required this.excludedUserIds,
    required this.candidates,
    required this.controller,
  });

  final String questId;

  final Set<String> excludedUserIds;
  final List<Ally> candidates;
  final QuestListController controller;

  @override
  State<_InviteAlliesSheet> createState() => _InviteAlliesSheetState();
}

class _InviteAlliesSheetState extends State<_InviteAlliesSheet> {
  final _selectedIds = <String>{};
  final _searchController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    Get.find<AlliesController>().clearSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
            TextField(
              controller: _searchController,
              onChanged: (value) {
                Get.find<AlliesController>().search(value);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un membre Ndeli…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.candidates.isNotEmpty) ...[
              Text(
                'VOS ALLIÉS',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
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
                  activeColor: AppColors.volt,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
            Obx(() {
              final allies = Get.find<AlliesController>();
              final query = allies.searchQuery.value;
              final acceptedIds = widget.candidates
                  .map((ally) => ally.id)
                  .toSet();
              final members = query.length < 2
                  ? const <UserSearchResult>[]
                  : allies.searchResults
                        .where(
                          (user) =>
                              !widget.excludedUserIds.contains(user.id) &&
                              !acceptedIds.contains(user.id),
                        )
                        .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'AUTRES MEMBRES',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    for (final user in members)
                      CheckboxListTile(
                        value: _selectedIds.contains(user.id),
                        onChanged: (checked) => setState(() {
                          checked == true
                              ? _selectedIds.add(user.id)
                              : _selectedIds.remove(user.id);
                        }),
                        title: Text(
                          '${user.firstName} ${user.lastName}',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        activeColor: AppColors.volt,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                  if (query.length >= 2 && allies.isSearching.value)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.volt,
                      ),
                    ),
                  if (query.length >= 2 &&
                      !allies.isSearching.value &&
                      members.isEmpty)
                    Text(
                      'Aucun autre membre trouvé.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Text(
              'En acceptant, cette personne rejoindra votre quête et deviendra votre alliée.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
            ...[
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

/// Every member's progress for a collective quest — fetches once on mount
/// and caches the result on the controller (keyed by groupId), same
/// rationale as [QuestListController.loadDeletionRequest].
class _GroupMembersSection extends StatefulWidget {
  const _GroupMembersSection({required this.quest, required this.controller});

  final QuestModel quest;
  final QuestListController controller;

  @override
  State<_GroupMembersSection> createState() => _GroupMembersSectionState();
}

class _GroupMembersSectionState extends State<_GroupMembersSection> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadGroupProgress(widget.quest.groupId!);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = widget.controller.groupProgress[widget.quest.groupId];
      if (progress == null) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final member in progress.members) ...[
            _GroupMemberRow(member: member),
            if (member != progress.members.last) const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _inviteMembers(context, progress),
            child: Text(
              'INVITER UN MEMBRE',
              style: AppTypography.labelMd.copyWith(color: AppColors.volt),
            ),
          ),
        ],
      );
    });
  }

  void _inviteMembers(BuildContext context, QuestGroupProgress progress) {
    final allies = Get.find<AlliesController>();
    final alreadyMembers = progress.members.map((m) => m.userId).toSet();
    showAppBottomSheet(
      context,
      builder: (context) => _InviteGroupMembersSheet(
        groupId: widget.quest.groupId!,
        excludedUserIds: alreadyMembers,
        candidates: allies.allies
            .where((a) => !alreadyMembers.contains(a.id))
            .toList(),
        controller: widget.controller,
      ),
    );
  }
}

class _GroupMemberRow extends StatelessWidget {
  const _GroupMemberRow({required this.member});

  final QuestGroupMemberProgress member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            member.name.isEmpty ? 'Membre' : member.name,
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: SegmentedProgress(ratio: member.progress, height: 10),
        ),
        const SizedBox(width: 12),
        Text(
          '${member.streakDays}j',
          style: AppTypography.labelMd.copyWith(
            color: AppColors.volt,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InviteGroupMembersSheet extends StatefulWidget {
  const _InviteGroupMembersSheet({
    required this.groupId,
    required this.excludedUserIds,
    required this.candidates,
    required this.controller,
  });

  final String groupId;
  final Set<String> excludedUserIds;
  final List<Ally> candidates;
  final QuestListController controller;

  @override
  State<_InviteGroupMembersSheet> createState() =>
      _InviteGroupMembersSheetState();
}

class _InviteGroupMembersSheetState extends State<_InviteGroupMembersSheet> {
  final _selectedIds = <String>{};
  final _searchController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    Get.find<AlliesController>().clearSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _isSending = true);
    final ok = await widget.controller.inviteGroupMembers(
      widget.groupId,
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
              'INVITER UN MEMBRE SUR CETTE QUÊTE COLLECTIVE',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                Get.find<AlliesController>().search(value);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un membre Ndeli…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.candidates.isNotEmpty) ...[
              Text(
                'VOS ALLIÉS',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
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
                  activeColor: AppColors.volt,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
            Obx(() {
              final allies = Get.find<AlliesController>();
              final query = allies.searchQuery.value;
              final acceptedIds = widget.candidates
                  .map((ally) => ally.id)
                  .toSet();
              final members = query.length < 2
                  ? const <UserSearchResult>[]
                  : allies.searchResults
                        .where(
                          (user) =>
                              !widget.excludedUserIds.contains(user.id) &&
                              !acceptedIds.contains(user.id),
                        )
                        .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'AUTRES MEMBRES',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    for (final user in members)
                      CheckboxListTile(
                        value: _selectedIds.contains(user.id),
                        onChanged: (checked) => setState(() {
                          checked == true
                              ? _selectedIds.add(user.id)
                              : _selectedIds.remove(user.id);
                        }),
                        title: Text(
                          '${user.firstName} ${user.lastName}',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        activeColor: AppColors.volt,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                  if (query.length >= 2 && allies.isSearching.value)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.volt,
                      ),
                    ),
                  if (query.length >= 2 &&
                      !allies.isSearching.value &&
                      members.isEmpty)
                    Text(
                      'Aucun autre membre trouvé.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 12),
            Text(
              'En acceptant, cette personne rejoindra votre quête collective avec sa propre quête et validera les vôtres.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
            ...[
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
        color: const Color(0xFF220F10),
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: const Color(0xFF4A2525)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOTE DE SUPPRESSION',
            style: AppTypography.labelMd.copyWith(color: AppColors.errorSoft, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Suppression en attente d\'approbation '
            '(${request.votes.approved}/${request.votes.total} alliés)',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _PendingPauseBanner extends StatelessWidget {
  const _PendingPauseBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF221C0C),
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: const Color(0xFF4A3B12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAUSE EN ATTENTE D\'UN ALLIÉ',
            style: AppTypography.labelMd.copyWith(color: AppColors.amber, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Demande de pause en attente de validation par un allié.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _PausedBanner extends StatefulWidget {
  const _PausedBanner({required this.quest, required this.controller});

  final QuestModel quest;
  final QuestListController controller;

  @override
  State<_PausedBanner> createState() => _PausedBannerState();
}

class _PausedBannerState extends State<_PausedBanner> {
  bool _resuming = false;
  String? _error;

  Future<void> _resume() async {
    setState(() {
      _resuming = true;
      _error = null;
    });
    final ok = await widget.controller.resumeQuest(widget.quest.id);
    if (!mounted) return;
    setState(() {
      _resuming = false;
      if (!ok) _error = widget.controller.errorMessage.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUÊTE EN PAUSE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outlineMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Quête en pause — les pointages sont suspendus et l\'échéance '
            'sera repoussée d\'autant à la reprise.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTypography.bodyMd.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: _resuming ? 'REPRISE…' : 'REPRENDRE',
            variant: AppButtonVariant.secondary,
            fullWidth: false,
            onPressed: _resuming ? null : _resume,
          ),
        ],
      ),
    );
  }
}

/// Text-only proof for v1 — "sick mode" is meant for a quick, low-friction
/// exception; photo/video proof is already supported by the backend
/// (CreatePauseRequestDto mirrors CreateEvidenceDto) but isn't wired up here
/// yet since reviewing a photo/video proof needs its own file-streaming
/// bridge for the deciding ally (the check-in proof one is Evidence-specific
/// and this feature deliberately doesn't reuse Evidence).
class _RequestPauseSheet extends StatefulWidget {
  const _RequestPauseSheet({required this.quest, required this.controller});

  final QuestModel quest;
  final QuestListController controller;

  @override
  State<_RequestPauseSheet> createState() => _RequestPauseSheetState();
}

class _RequestPauseSheetState extends State<_RequestPauseSheet> {
  final _reasonController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Merci d\'indiquer la raison de la pause.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final ok = await widget.controller.requestPause(
      widget.quest.id,
      reason: reason,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _sending = false;
      _error = widget.controller.errorMessage.value;
    });
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
              'METTRE LA QUÊTE EN PAUSE',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 8),
            Text(
              widget.quest.allies.isEmpty
                  ? 'Aucun allié sur cette quête : la pause prend effet immédiatement.'
                  : 'Un allié devra valider cette pause avant qu\'elle ne prenne effet.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              autofocus: true,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: 'Raison de la pause (ex : maladie)...',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'ENVOYER LA DEMANDE',
              loading: _sending,
              onPressed: _sending ? null : _send,
            ),
          ],
        ),
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
        final reversed = checkIns.reversed.toList();
        return SizedBox(
          height: 420,
          child: ListView.separated(
            itemCount: reversed.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _CheckInRow(checkIn: reversed[index]),
          ),
        );
      },
    );
  }
}

class _FocusSessionHistory extends StatelessWidget {
  const _FocusSessionHistory({required this.questId});

  final String questId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FocusSessionHistory>(
      future: Get.find<QuestListController>().fetchFocusSessions(questId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 1)),
          );
        }
        final history = snapshot.data!;
        if (history.sessions.isEmpty) {
          return Text(
            'Aucune session de focus pour le moment.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${history.todayMinutes} minute(s) de focus aujourd\'hui',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.volt,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final session in history.sessions) ...[
              _FocusSessionRow(session: session),
              if (session != history.sessions.last) const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _FocusSessionRow extends StatelessWidget {
  const _FocusSessionRow({required this.session});

  final FocusSession session;

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final start = session.startedAt.toLocal();
    final end = session.endedAt.toLocal();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${two(start.hour)}:${two(start.minute)} – ${two(end.hour)}:${two(end.minute)}',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
          Text(
            '${session.durationMinutes} min',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
    final reviewComment = latestEvidence?.reviewComment;
    final hasReviewComment = reviewComment != null && reviewComment.isNotEmpty;
    final reviewer = latestEvidence?.reviewedBy;
    final submitterComment = latestEvidence?.description;
    final hasSubmitterComment =
        submitterComment != null && submitterComment.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    ? AppColors.volt
                    : switch (latestEvidence.status) {
                        EvidenceStatus.approved => AppColors.volt,
                        EvidenceStatus.rejected => AppColors.error,
                        EvidenceStatus.pending => AppColors.outline,
                      },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${checkIn.date.day.toString().padLeft(2, '0')}/${checkIn.date.month.toString().padLeft(2, '0')}/${checkIn.date.year}',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
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
                      EvidenceStatus.approved => AppColors.volt,
                      EvidenceStatus.rejected => AppColors.error,
                      EvidenceStatus.pending => AppColors.outline,
                    },
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          if (hasSubmitterComment)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 28),
              child: Text(
                'Votre commentaire : $submitterComment',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (reviewer != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 28),
              child: Text(
                hasReviewComment
                    ? '${reviewer.fullName} : $reviewComment'
                    : switch (latestEvidence?.status) {
                        EvidenceStatus.rejected =>
                          '${reviewer.fullName} a rejeté cette preuve',
                        _ => '${reviewer.fullName} a validé cette preuve',
                      },
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else if (hasReviewComment)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 28),
              child: Text(
                'Commentaire de l\'allié : $reviewComment',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                  fontStyle: FontStyle.italic,
                ),
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
