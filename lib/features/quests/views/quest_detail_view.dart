import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/avatar_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/borders/dashed_rrect_painter.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally.dart';
import '../../social/models/user_search_result.dart';
import '../controllers/quest_list_controller.dart';
import '../models/check_in_model.dart';
import '../models/quest_deletion_request.dart';
import '../models/quest_group_progress.dart';
import '../models/quest_model.dart';
import '../models/quest_pause_request.dart';
import '../utils/quest_period_status.dart';
import '../services/evidence_picker_service.dart';
import '../utils/quest_kind.dart';

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
    final currentUserId = Get.find<AuthController>().user.value?.id;
    return Scaffold(
      body: Column(
        children: [
          Obx(() {
            final quest = controller.findById(questId);
            return SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(13),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Text(
                          '←',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    if (quest != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'QUÊTE ${questKindLabels[questKindFor(quest, currentUserId)]}',
                          style: TextStyle(
                            fontFamily: 'Geist Mono',
                            fontSize: 11,
                            letterSpacing: 0.14 * 11,
                            color: quest.isCollective
                                ? AppColors.emberLight
                                : AppColors.volt,
                          ),
                        ),
                      ),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1509),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: 0.7853981633974483,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.emberBright,
                                      AppColors.emberDeep,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '${quest.streakDays}',
                              style: const TextStyle(
                                fontFamily: 'Unbounded',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.emberLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
            );
          }),
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
              return _QuestDetailBody(
                quest: quest,
                currentUserId: currentUserId,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QuestDetailBody extends GetView<QuestListController> {
  const _QuestDetailBody({required this.quest, required this.currentUserId});

  final QuestModel quest;
  final String? currentUserId;

  static const _statusLabels = {
    QuestStatus.pendingPayment: 'EN ATTENTE DE PAIEMENT',
    QuestStatus.paused: 'QUÊTE EN PAUSE',
    QuestStatus.completed: 'QUÊTE RÉUSSIE',
    QuestStatus.failed: 'QUÊTE ÉCHOUÉE',
  };

  int get _currentPeriodNumber {
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(quest.startDate);
    final elapsedDays = today.difference(start).inDays + 1;
    final elapsed = quest.frequency == QuestFrequency.weekly
        ? (elapsedDays / 7).ceil()
        : elapsedDays;
    final total = expectedQuestPeriods(quest.frequency, quest.durationDays);
    return elapsed.clamp(1, total);
  }

  String get _statusLabel {
    if (quest.status == QuestStatus.active) {
      final total = expectedQuestPeriods(quest.frequency, quest.durationDays);
      final unit = quest.frequency == QuestFrequency.weekly ? 'SEM.' : 'JOUR';
      return 'EN COURS · $unit $_currentPeriodNumber/$total';
    }
    return _statusLabels[quest.status] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final velocityPercent = (quest.progress * 100).round();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(status: quest.status, label: _statusLabel),
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
          Container(
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
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'PROGRESSION',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      '$velocityPercent %',
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DayIntegrityBar(
                  quest: quest,
                  currentPeriod: _currentPeriodNumber,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quest.frequency == QuestFrequency.weekly
                          ? 'Semaine $_currentPeriodNumber sur '
                                '${expectedQuestPeriods(quest.frequency, quest.durationDays)}'
                          : 'Jour $_currentPeriodNumber sur '
                                '${expectedQuestPeriods(quest.frequency, quest.durationDays)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.outline,
                      ),
                    ),
                    Text(
                      'Seuil : ${quest.successThresholdPercent} %',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
            final canAct = quest.isActive && !isPendingDeletion;
            final pausePending =
                controller.pauseRequests[quest.id]?.status ==
                QuestPauseRequestStatus.pending;
            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: AppPressable(
                    color: canAct
                        ? AppColors.volt
                        : AppColors.surfaceContainerHighest,
                    shadowColor: canAct
                        ? AppColors.voltShadow
                        : const Color(0xFF0A0A0C),
                    shadowThickness: 5,
                    borderRadius: BorderRadius.circular(16),
                    enabled: canAct,
                    onTap: () => Get.toNamed(
                      AppRoutes.questValidation,
                      arguments: quest.id,
                    ),
                    child: Center(
                      child: Text(
                        'VALIDER AVEC PREUVE',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.06 * 14,
                          color: canAct
                              ? AppColors.onPrimary
                              : AppColors.outlineFaint,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryActionButton(
                        label: 'Ajouter un enjeu',
                        glyph: Text(
                          '+',
                          style: AppTypography.headlineMd.copyWith(
                            fontSize: 15,
                            color: AppColors.volt,
                          ),
                        ),
                        onTap: (canAct && !quest.hasStake)
                            ? () => _addStake(context, quest)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SecondaryActionButton(
                        label: 'Mode malade',
                        glyph: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 13,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 3),
                            Container(
                              width: 4,
                              height: 13,
                              color: AppColors.amber,
                            ),
                          ],
                        ),
                        onTap: (canAct && !pausePending)
                            ? () => _requestPause(context, quest)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SecondaryActionButton(
                        label: 'Focus · bientôt',
                        glyph: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outlineFaint,
                              width: 2,
                            ),
                          ),
                        ),
                        onTap: null,
                      ),
                    ),
                  ],
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2210),
                      borderRadius: AppRadii.structuralRadius,
                      border: Border.all(color: const Color(0xFF2F3F14)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EN JEU',
                          style: AppTypography.labelMd.copyWith(
                            fontSize: 10.5,
                            color: const Color(0xFFA9CF4A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quest.stakeAmountXof != null
                              ? formatXof(quest.stakeAmountXof!)
                              : 'Aucun enjeu',
                          style: const TextStyle(
                            fontFamily: 'Unbounded',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: AppColors.volt,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quest.stakeAmountXof == null
                              ? 'Aucune mise sur cette quête.'
                              : (quest.fundsDistribution ==
                                        FundsDistribution.allies
                                    ? "En cas d'échec : partagé entre "
                                          '${_acceptedAllyCount(quest)} '
                                          '${_acceptedAllyCount(quest) > 1 ? 'alliés' : 'allié'}.'
                                    : "En cas d'échec : donné à une association."),
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Color(0xFFA9B98A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                        Text(
                          'RISQUE DÉCLARÉ',
                          style: AppTypography.labelMd.copyWith(
                            fontSize: 10.5,
                            color: AppColors.outlineMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            final filled = i < _riskBarCount[quest.riskLevel]!;
                            const heights = [10.0, 17.0, 24.0];
                            return Container(
                              width: 12,
                              height: heights[i],
                              margin: EdgeInsets.only(right: i == 2 ? 0 : 4),
                              decoration: BoxDecoration(
                                color: filled
                                    ? AppColors.ember
                                    : AppColors.surfaceBright,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _riskLabels[quest.riskLevel] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Unbounded',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.emberLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (quest.isCollective) ...[
            const SizedBox(height: 32),
            Text(
              "L'ESCOUADE · CLASSEMENT",
              style: AppTypography.labelMd.copyWith(
                color: AppColors.outlineMuted,
              ),
            ),
            const SizedBox(height: 16),
            _GroupMembersSection(
              quest: quest,
              controller: controller,
              currentUserId: currentUserId,
            ),
          ],
          const SizedBox(height: 32),
          Text(
            "REGISTRE D'INTÉGRITÉ",
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outlineMuted,
            ),
          ),
          const SizedBox(height: 16),
          _CheckInHistory(quest: quest),
          const SizedBox(height: 32),
          Text(
            'RÈGLES',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outlineMuted,
            ),
          ),
          const SizedBox(height: 16),
          _RulesGrid(quest: quest),
          const SizedBox(height: 32),
          Text(
            'ALLIÉS DE LA QUÊTE',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outlineMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (quest.isCollective)
            _GroupAlliesWrap(
              quest: quest,
              controller: controller,
              currentUserId: currentUserId,
            )
          else
            _QuestAlliesWrap(
              allies: quest.allies,
              onAdd: quest.isFinished
                  ? null
                  : () => _inviteAllies(context, quest),
            ),
          if (!quest.isFinished) ...[
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () => _confirmDeletion(context, quest),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: Color(0xFF3A1E1E)),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.interactiveRadius,
                ),
              ),
              child: Text(
                'Supprimer la quête',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorSoft,
                ),
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

  Future<void> _confirmDeletion(BuildContext context, QuestModel quest) async {
    final confirmed = await showAppBottomSheet<bool>(
      context,
      builder: (context) => _DeleteQuestSheet(quest: quest),
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
    QuestRiskLevel.medium: 'MOYEN',
    QuestRiskLevel.high: 'ÉLEVÉ',
  };

  static const _riskBarCount = {
    QuestRiskLevel.low: 1,
    QuestRiskLevel.medium: 2,
    QuestRiskLevel.high: 3,
  };
}

int _acceptedAllyCount(QuestModel quest) =>
    quest.allies.where((a) => a.status == QuestAllyStatus.accepted).length;

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

const _shortFrenchMonths = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _shortFrenchDate(DateTime date) =>
    '${date.day} ${_shortFrenchMonths[date.month - 1]}';

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
      QuestStatus.failed => (
        const Color(0xFF220F10),
        const Color(0xFF4A2525),
        AppColors.error,
      ),
      _ => (
        AppColors.surfaceContainerLow,
        AppColors.outlineVariant,
        AppColors.outlineMuted,
      ),
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
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
            color: selected ? AppColors.volt : AppColors.outlineVariant15,
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
                      child: CircularProgressIndicator(color: AppColors.volt),
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
  const _GroupMembersSection({
    required this.quest,
    required this.controller,
    required this.currentUserId,
  });

  final QuestModel quest;
  final QuestListController controller;
  final String? currentUserId;

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
      final ranked = [...progress.members]
        ..sort((a, b) => b.progress.compareTo(a.progress));
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.structuralRadius,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            for (var i = 0; i < ranked.length; i++)
              _GroupMemberRow(
                position: i + 1,
                member: ranked[i],
                isSelf: ranked[i].userId == widget.currentUserId,
              ),
          ],
        ),
      );
    });
  }
}

class _GroupMemberRow extends StatelessWidget {
  const _GroupMemberRow({
    required this.position,
    required this.member,
    required this.isSelf,
  });

  final int position;
  final QuestGroupMemberProgress member;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final color = isSelf ? AppColors.volt : avatarColorForId(member.userId);
    final positionColor = position == 1
        ? AppColors.gold
        : AppColors.outlineMuted;
    final name = isSelf
        ? 'Toi'
        : (member.name.isEmpty ? 'Membre' : member.name);
    return Container(
      color: isSelf ? AppColors.voltTint(0.06) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$position',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: positionColor,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              initialsFor(member.firstName ?? '', member.lastName ?? ''),
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${(member.progress * 100).round()} %',
                      style: const TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: member.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.rotate(
                  angle: 0.7853981633974483,
                  child: Container(width: 7, height: 7, color: AppColors.ember),
                ),
                const SizedBox(width: 5),
                Text(
                  '${member.streakDays}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.emberLight,
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

/// Group co-participants, excluding the current user — mirrors
/// [_QuestAlliesWrap]'s chip style for a solo quest's allies.
class _GroupAlliesWrap extends StatefulWidget {
  const _GroupAlliesWrap({
    required this.quest,
    required this.controller,
    required this.currentUserId,
  });

  final QuestModel quest;
  final QuestListController controller;
  final String? currentUserId;

  @override
  State<_GroupAlliesWrap> createState() => _GroupAlliesWrapState();
}

class _GroupAlliesWrapState extends State<_GroupAlliesWrap> {
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
      final others = progress.members
          .where((m) => m.userId != widget.currentUserId)
          .toList();
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final member in others)
            _AllyChip(
              userId: member.userId,
              firstName: member.firstName ?? '',
              lastName: member.lastName ?? '',
            ),
          if (!widget.quest.isFinished)
            _AddAllyChip(onTap: () => _inviteMembers(context, progress)),
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
                      child: CircularProgressIndicator(color: AppColors.volt),
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

/// "Abandonner la quête ?" — confirmation sheet for [QuestListController.requestDeletion].
/// When the quest has accountability allies, deletion isn't immediate: every
/// accepted ally must approve, so the CTA requests their vote instead of
/// deleting outright.
class _DeleteQuestSheet extends StatelessWidget {
  const _DeleteQuestSheet({required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context) {
    final accepted = quest.allies
        .where((a) => a.status == QuestAllyStatus.accepted)
        .toList();
    final (body, buttonLabel) = switch (accepted.length) {
      0 when quest.hasStake => (
        'Votre mise vous sera remboursée immédiatement.',
        'SUPPRIMER LA QUÊTE',
      ),
      0 => (
        'Cette action est immédiate et irréversible.',
        'SUPPRIMER LA QUÊTE',
      ),
      1 => (
        'Ton allié doit approuver. Un refus et la quête est considérée comme échouée.',
        'DEMANDER LE VOTE',
      ),
      _ => (
        'Tes ${accepted.length} alliés doivent tous approuver. Un seul refus et '
            'la quête est considérée comme échouée.',
        'DEMANDER LE VOTE',
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUPPRESSION',
          style: TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: 11,
            letterSpacing: 0.14 * 11,
            color: AppColors.errorSoft,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Abandonner la quête ?',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            height: 1.15,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.outline,
          ),
        ),
        if (accepted.isNotEmpty) ...[
          const SizedBox(height: 20),
          for (final ally in accepted) ...[
            _AllyVoteRow(ally: ally),
            if (ally != accepted.last) const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 58,
          child: AppPressable(
            color: const Color(0xFFEC6762),
            shadowColor: const Color(0xFF7F312E),
            shadowThickness: 5,
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(true),
            child: Center(
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.06 * 14,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annuler',
              style: TextStyle(fontSize: 14, color: AppColors.outline),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllyVoteRow extends StatelessWidget {
  const _AllyVoteRow({required this.ally});

  final QuestAllyRef ally;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColorForId(ally.userId),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initialsFor(ally.firstName, ally.lastName),
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${ally.firstName} ${ally.lastName}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, color: AppColors.primary),
            ),
          ),
          Text(
            'VOTE REQUIS',
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: 10.5,
              letterSpacing: 0.1 * 10.5,
              color: AppColors.outlineMuted,
            ),
          ),
        ],
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
            style: AppTypography.labelMd.copyWith(
              color: AppColors.errorSoft,
              fontSize: 11,
            ),
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
            style: AppTypography.labelMd.copyWith(
              color: AppColors.amber,
              fontSize: 11,
            ),
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
            style: AppTypography.labelMd.copyWith(
              color: AppColors.outlineMuted,
              fontSize: 11,
            ),
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
  PickedEvidence? _photo;
  String? _error;

  Future<void> _pickPhoto(ImageSource source) async {
    FocusScope.of(context).unfocus();
    try {
      final picked = await Get.find<EvidencePickerService>().pickPhoto(source);
      if (picked != null && mounted) {
        setState(() {
          _photo = picked;
          _error = null;
        });
      }
    } on EvidencePickerException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible d’ajouter cette photo.');
    }
  }

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
      photo: _photo,
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
              autofocus: false,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: 'Raison de la pause (ex : maladie)...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_photo == null) ...[
              Text(
                'PREUVE FACULTATIVE',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 8),
              Text(
                'Une photo peut aider ton allié à comprendre ta demande.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadii.interactiveRadius,
                  border: Border.all(color: AppColors.outlineVariantStrong),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ajouter une photo',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    PopupMenuButton<ImageSource>(
                      enabled: !_sending,
                      tooltip: 'Choisir une photo',
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.volt,
                      ),
                      onSelected: _pickPhoto,
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: ImageSource.camera,
                          child: Text('Prendre une photo'),
                        ),
                        PopupMenuItem(
                          value: ImageSource.gallery,
                          child: Text('Choisir dans la galerie'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.interactiveRadius,
                    child: Image.memory(
                      _photo!.bytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Photo prête à envoyer',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer la photo',
                    onPressed: _sending
                        ? null
                        : () => setState(() => _photo = null),
                    icon: const Icon(Icons.close, color: AppColors.outline),
                  ),
                ],
              ),
            ],
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
  const _CheckInHistory({required this.quest});

  final QuestModel quest;

  String _labelFor(CheckIn checkIn) {
    if (quest.frequency != QuestFrequency.weekly) {
      return _shortFrenchDate(checkIn.date);
    }
    final weekIndex =
        _dateOnly(checkIn.date).difference(_dateOnly(quest.startDate)).inDays ~/
        7;
    return 'Sem. ${weekIndex + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CheckIn>>(
      future: Get.find<QuestListController>().fetchCheckIns(quest.id),
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
            itemBuilder: (context, index) => _CheckInRow(
              checkIn: reversed[index],
              label: _labelFor(reversed[index]),
            ),
          ),
        );
      },
    );
  }
}

class _CheckInRow extends StatelessWidget {
  const _CheckInRow({required this.checkIn, required this.label});

  final String label;

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

    final (pillBg, pillColor, pillLabel) = switch (latestEvidence?.status) {
      EvidenceStatus.approved ||
      null => (const Color(0xFF1E2610), AppColors.volt, 'APPROUVÉE'),
      EvidenceStatus.rejected => (
        const Color(0xFF2A1213),
        AppColors.error,
        'REJETÉE',
      ),
      EvidenceStatus.pending => (
        AppColors.surfaceContainerHighest,
        AppColors.outline,
        'EN ATTENTE',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  pillLabel,
                  style: TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: 10.5,
                    letterSpacing: 0.12 * 10.5,
                    color: pillColor,
                  ),
                ),
              ),
            ],
          ),
          if (hasSubmitterComment) ...[
            const SizedBox(height: 8),
            Text(
              '« $submitterComment »',
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Color(0xFFC8C8CE),
              ),
            ),
          ],
          if (reviewer != null || hasReviewComment) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.surfaceBright, width: 2),
                ),
              ),
              child: Text(
                reviewer != null
                    ? (hasReviewComment
                          ? '${reviewer.fullName} : « $reviewComment »'
                          : switch (latestEvidence?.status) {
                              EvidenceStatus.rejected =>
                                '${reviewer.fullName} a rejeté cette preuve.',
                              _ => '${reviewer.fullName} a approuvé.',
                            })
                    : '« $reviewComment »',
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.outlineMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.glyph,
    this.onTap,
  });

  final String label;
  final Widget glyph;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph,
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: onTap != null ? AppColors.primary : AppColors.outlineFaint,
          ),
        ),
      ],
    );

    if (onTap == null) {
      return CustomPaint(
        painter: const DashedRRectPainter(
          color: AppColors.outlineVariantStrong,
          radius: AppRadii.interactive,
        ),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: content,
        ),
      );
    }
    return SizedBox(
      height: 64,
      child: AppPressable(
        color: AppColors.surfaceContainerLow,
        shadowColor: const Color(0xFF0A0A0C),
        shadowThickness: 3,
        border: Border.all(color: AppColors.outlineVariantStrong),
        onTap: onTap,
        child: Center(child: content),
      ),
    );
  }
}

/// One visible segment per day or quest-anchored week, colored from the real
/// check-ins returned by the API.
class _DayIntegrityBar extends StatefulWidget {
  const _DayIntegrityBar({required this.quest, required this.currentPeriod});

  final QuestModel quest;
  final int currentPeriod;

  @override
  State<_DayIntegrityBar> createState() => _DayIntegrityBarState();
}

class _DayIntegrityBarState extends State<_DayIntegrityBar> {
  late Future<List<CheckIn>> _checkIns;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _DayIntegrityBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest) _load();
  }

  void _load() {
    _checkIns = Get.find<QuestListController>().fetchCheckIns(widget.quest.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CheckIn>>(
      future: _checkIns,
      builder: (context, snapshot) {
        final checkIns = snapshot.data;
        final total = expectedQuestPeriods(
          widget.quest.frequency,
          widget.quest.durationDays,
        );
        return SizedBox(
          height: 14,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var period = 1; period <= total; period++) ...[
                if (period > 1) const SizedBox(width: 3),
                Expanded(
                  child: DecoratedBox(
                    key: Key('quest-progress-period-$period'),
                    decoration: BoxDecoration(
                      color: _colorFor(
                        checkIns == null
                            ? QuestPeriodStatus.future
                            : questPeriodStatus(
                                widget.quest,
                                checkIns,
                                period,
                                widget.currentPeriod,
                              ),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _colorFor(QuestPeriodStatus status) => switch (status) {
    QuestPeriodStatus.success => AppColors.volt,
    QuestPeriodStatus.missed => AppColors.error,
    QuestPeriodStatus.inProgress => const Color(0xFF55555E),
    QuestPeriodStatus.future => AppColors.surfaceContainerHighest,
  };
}

/// 2-column grid of the quest's rules — cells share 1px dividers via the
/// outer container's background showing through the gaps, matching the
/// mockup's CSS-grid `gap: 1px` treatment.
class _RulesGrid extends StatelessWidget {
  const _RulesGrid({required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context) {
    final periodUnit = quest.frequency == QuestFrequency.daily
        ? 'jour'
        : 'semaine';
    final periodUnitPlural = quest.frequency == QuestFrequency.daily
        ? 'jours'
        : 'semaines';
    final rules = [
      (
        'Fréquence',
        quest.frequency == QuestFrequency.daily
            ? 'Quotidienne'
            : 'Hebdomadaire',
      ),
      ('Objectif', '${quest.targetPerPeriod}× par $periodUnit'),
      (
        'Absences tolérées',
        '${toleratedMissedPeriods(frequency: quest.frequency, durationDays: quest.durationDays, successThresholdPercent: quest.successThresholdPercent)} '
            '$periodUnitPlural',
      ),
      ('Échéance', _shortFrenchDate(quest.deadline)),
      ('Rattrapage', '${quest.gracePeriodDays} jours'),
      ('Preuve', quest.requiresProof ? 'Obligatoire' : 'Facultative'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.outlineVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: 1),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RuleTile(rules[row * 2].$1, rules[row * 2].$2),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: _RuleTile(
                      rules[row * 2 + 1].$1,
                      rules[row * 2 + 1].$2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.outlineMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quest allies as chips (avatar + name) — [onAdd] is null once the quest
/// is finished, hiding the "add" chip.
class _QuestAlliesWrap extends StatelessWidget {
  const _QuestAlliesWrap({required this.allies, required this.onAdd});

  final List<QuestAllyRef> allies;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (allies.isEmpty && onAdd == null) {
      return Text(
        'Aucun allié sur cette quête pour le moment.',
        style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ally in allies)
          Opacity(
            opacity: ally.status == QuestAllyStatus.accepted ? 1 : 0.5,
            child: _AllyChip(
              userId: ally.userId,
              firstName: ally.firstName,
              lastName: ally.lastName,
            ),
          ),
        if (onAdd != null) _AddAllyChip(onTap: onAdd!),
      ],
    );
  }
}

class _AllyChip extends StatelessWidget {
  const _AllyChip({
    required this.userId,
    required this.firstName,
    required this.lastName,
  });

  final String userId;
  final String firstName;
  final String lastName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColorForId(userId),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              initialsFor(firstName, lastName),
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$firstName $lastName',
            style: const TextStyle(fontSize: 13.5, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _AddAllyChip extends StatelessWidget {
  const _AddAllyChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariantStrong),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: AppColors.volt),
            SizedBox(width: 6),
            Text(
              'Ajouter',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.volt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
