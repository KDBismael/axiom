import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/user_search_result.dart';
import '../controllers/quest_create_controller.dart';
import '../models/quest_model.dart';

class QuestCreateView extends GetView<QuestCreateController> {
  const QuestCreateView({super.key});

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
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'QUITTER',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final step = controller.currentStep.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ÉTAPE ${(step + 1).toString().padLeft(2, '0')} — 0${controller.stepCount}',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(controller.stepCount, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: i == controller.stepCount - 1 ? 0 : 4,
                                ),
                                color: i <= step
                                    ? AppColors.primary
                                    : AppColors.surfaceContainerHighest,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: _stepBody(step),
                    ),
                  ),
                  Obx(() {
                    final error = controller.errorMessage.value;
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Text(
                        error,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ),
          _Footer(controller: controller),
        ],
      ),
    );
  }

  Widget _stepBody(int step) {
    final steps = <Widget>[
      _TitleStep(controller: controller),
      if (controller.createForSomeoneElse.value)
        _InviteeStep(controller: controller),
      _ScheduleRulesStep(controller: controller),
      _AlliesStep(controller: controller),
      _StakeStep(controller: controller),
      _ReviewStep(controller: controller),
    ];
    return steps[step.clamp(0, steps.length - 1)];
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return GlassChrome(
      safeAreaBottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Obx(() {
          final step = controller.currentStep.value;
          final isLastStep = step == controller.stepCount - 1;
          final onInviteeStep =
              controller.createForSomeoneElse.value &&
              step == QuestCreateController.inviteeStepIndex;
          final label = isLastStep ? 'LANCER LA QUÊTE' : 'SUIVANT';
          return Row(
            children: [
              TextButton(
                onPressed: controller.previousStep,
                child: Text(
                  'RETOUR',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  label: label,
                  loading: controller.isSubmitting.value,
                  onPressed:
                      (step == 0 && !controller.canProceedFromTitle) ||
                          (onInviteeStep && !controller.canProceedFromInvitee) ||
                          controller.isSubmitting.value
                      ? null
                      : () async {
                          if (isLastStep) {
                            final ok = await controller.submit();
                            if (!ok) return;
                            final quest = controller.createdQuest.value;
                            if (quest != null && quest.hasStake) {
                              Get.offNamed(
                                AppRoutes.questPayment,
                                arguments: quest.id,
                              );
                            } else {
                              if (controller.createForSomeoneElse.value) {
                                Get.snackbar(
                                  'Quête envoyée',
                                  "Invitation envoyée. La quête sera activée dès son acceptation.",
                                );
                              }
                              Get.back();
                            }
                          } else {
                            controller.nextStep();
                          }
                        },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _TitleStep extends StatelessWidget {
  const _TitleStep({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DÉFINIR LA QUÊTE',
          style: AppTypography.displayLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 32),
        Text(
          'TITRE DE LA QUÊTE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.titleController,
          style: AppTypography.titleLg.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'Lire 50 pages par jour',
            hintStyle: AppTypography.titleLg.copyWith(
              color: AppColors.surfaceBright,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'DESCRIPTION',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.descriptionController,
          maxLines: 3,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'Pourquoi cette quête compte pour vous...',
            hintStyle: AppTypography.bodyMd.copyWith(
              color: AppColors.surfaceBright,
            ),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: AppRadii.structuralRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.structuralRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Obx(
          () => _ToggleRow(
            label: 'Créer cette quête pour quelqu’un d’autre',
            value: controller.createForSomeoneElse.value,
            onChanged: (value) {
              controller.createForSomeoneElse.value = value;
              if (!value) controller.selectedInviteeId.value = null;
            },
          ),
        ),
      ],
    );
  }
}

class _ScheduleRulesStep extends StatelessWidget {
  const _ScheduleRulesStep({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DURÉE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller.durationController,
                keyboardType: TextInputType.number,
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 48,
                ),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8),
              child: Text(
                'JOURS',
                style: AppTypography.titleLg.copyWith(
                  color: AppColors.surfaceBright,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'FRÉQUENCE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: [
              _SelectOption(
                label: 'Quotidien',
                selected: controller.frequency.value == QuestFrequency.daily,
                onTap: () => controller.frequency.value = QuestFrequency.daily,
              ),
              const SizedBox(height: 8),
              _SelectOption(
                label: 'Hebdomadaire',
                selected: controller.frequency.value == QuestFrequency.weekly,
                onTap: () => controller.frequency.value = QuestFrequency.weekly,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'OBJECTIF PAR PÉRIODE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller.targetPerPeriodController,
                keyboardType: TextInputType.number,
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 48,
                ),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8),
              child: Obx(
                () => Text(
                  controller.frequency.value == QuestFrequency.daily
                      ? 'FOIS / JOUR'
                      : 'FOIS / SEMAINE',
                  style: AppTypography.titleLg.copyWith(
                    color: AppColors.surfaceBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'NIVEAU DE RISQUE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              for (final level in QuestRiskLevel.values) ...[
                Expanded(
                  child: _SelectOption(
                    label: switch (level) {
                      QuestRiskLevel.low => 'Faible',
                      QuestRiskLevel.medium => 'Modéré',
                      QuestRiskLevel.high => 'Élevé',
                    },
                    selected: controller.riskLevel.value == level,
                    onTap: () => controller.riskLevel.value = level,
                  ),
                ),
                if (level != QuestRiskLevel.values.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        Obx(
          () => _ToggleRow(
            label: 'Preuve requise à chaque validation',
            value: controller.requiresProof.value,
            onChanged: (value) => controller.requiresProof.value = value,
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final expected = controller.expectedPeriods;
          final missed = controller.missedPeriodsAllowed;
          final unit = controller.frequency.value == QuestFrequency.daily
              ? (missed == 1 ? 'jour' : 'jours')
              : (missed == 1 ? 'semaine' : 'semaines');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ABSENCES TOLÉRÉES',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 8),
              Text(
                '$missed $unit sans conséquence',
                style: AppTypography.titleLg.copyWith(color: AppColors.primary),
              ),
              if (expected > 1) ...[
                const SizedBox(height: 8),
                Slider(
                  value: (expected - 1 - missed).toDouble(),
                  min: 0,
                  max: (expected - 1).toDouble(),
                  divisions: expected - 1,
                  activeColor: AppColors.emerald,
                  inactiveColor: AppColors.outlineVariant15,
                  label: '$missed $unit toléré${missed > 1 ? 's' : ''}',
                  onChanged: (value) => controller.setMissedPeriodsAllowed(
                    expected - 1 - value.round(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PLUS SOUPLE',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'PLUS STRICT',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Objectif : valider au moins ${controller.requiredPeriods} '
                '${controller.frequency.value == QuestFrequency.daily ? (controller.requiredPeriods == 1 ? 'jour' : 'jours') : (controller.requiredPeriods == 1 ? 'semaine' : 'semaines')} '
                'sur $expected.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
              if (controller.targetPerPeriod > 1) ...[
                const SizedBox(height: 4),
                Text(
                  '${controller.targetPerPeriod} validations sont nécessaires '
                  'pour réussir chaque ${controller.frequency.value == QuestFrequency.daily ? 'jour' : 'semaine'}.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ],
          );
        }),
        const SizedBox(height: 24),
        Text(
          'JOURS DE RATTRAPAGE APRÈS L’ÉCHÉANCE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.gracePeriodController,
          keyboardType: TextInputType.number,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ces jours permettent de compléter des validations après la date '
          'prévue. Ils ne changent pas le nombre d’absences tolérées.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}

class _SelectOption extends StatelessWidget {
  const _SelectOption({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : Colors.transparent,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
          borderRadius: AppRadii.interactiveRadius,
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: AppTypography.labelMd.copyWith(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryFixed,
        ),
      ],
    );
  }
}

class _InviteeStep extends StatefulWidget {
  const _InviteeStep({required this.controller});

  final QuestCreateController controller;

  @override
  State<_InviteeStep> createState() => _InviteeStepState();
}

class _InviteeStepState extends State<_InviteeStep> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.inviteeSearchInitialized) {
      Get.find<AlliesController>().clearSearch();
      widget.controller.inviteeSearchInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allies = Get.find<AlliesController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'POUR QUI EST CETTE QUÊTE ?',
          style: AppTypography.displayLg.copyWith(
            color: AppColors.primary,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Choisissez la personne qui recevra cette quête. Elle devra "
          "l'accepter pour en devenir propriétaire ; vous deviendrez alors "
          "automatiquement son allié de responsabilité.",
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.outline,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: widget.controller.inviteeSearchController,
          onChanged: (value) => allies.search(value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Rechercher un membre Ndeli…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final query = allies.searchQuery.value;
          final members = query.length < 2
              ? const <UserSearchResult>[]
              : allies.searchResults;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final user in members) ...[
                Obx(
                  () => _SelectOption(
                    label: '${user.firstName} ${user.lastName}',
                    selected:
                        widget.controller.selectedInviteeId.value == user.id,
                    onTap: () => widget.controller.selectInvitee(user.id),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (query.length >= 2 && allies.isSearching.value)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.emerald),
                ),
              if (query.length >= 2 &&
                  !allies.isSearching.value &&
                  members.isEmpty)
                Text(
                  'Aucun membre trouvé.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _AlliesStep extends StatefulWidget {
  const _AlliesStep({required this.controller});

  final QuestCreateController controller;

  @override
  State<_AlliesStep> createState() => _AlliesStepState();
}

class _AlliesStepState extends State<_AlliesStep> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.questSearchInitialized) {
      Get.find<AlliesController>().clearSearch();
      widget.controller.questSearchInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allies = Get.find<AlliesController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ALLIÉS DE LA QUÊTE',
          style: AppTypography.displayLg.copyWith(
            color: AppColors.primary,
            fontSize: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Invitez des amis à devenir alliés de cette quête : ils devront valider vos preuves, "
          "approuver une éventuelle suppression, et pourraient recevoir votre mise si vous échouez. "
          "Ils doivent accepter avant de compter comme alliés.",
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.outline,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: widget.controller.allySearchController,
          onChanged: (value) {
            allies.search(value);
          },
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Rechercher un membre Ndeli…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final allyIds = allies.allies.map((ally) => ally.id).toSet();
          final query = allies.searchQuery.value;
          final otherMembers = query.length < 2
              ? const <UserSearchResult>[]
              : allies.searchResults
                    .where((user) => !allyIds.contains(user.id))
                    .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allies.allies.isNotEmpty) ...[
                Text(
                  'VOS ALLIÉS',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              for (final ally in allies.allies) ...[
                Obx(
                  () => _SelectOption(
                    label: '${ally.firstName} ${ally.lastName}',
                    selected: widget.controller.selectedAllyIds.contains(
                      ally.id,
                    ),
                    onTap: () => widget.controller.toggleAlly(ally.id),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (otherMembers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'AUTRES MEMBRES',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
                const SizedBox(height: 8),
                for (final user in otherMembers) ...[
                  Obx(
                    () => _SelectOption(
                      label: '${user.firstName} ${user.lastName}',
                      selected: widget.controller.selectedAllyIds.contains(
                        user.id,
                      ),
                      onTap: () => widget.controller.toggleAlly(user.id),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              if (query.length >= 2 && allies.isSearching.value)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.emerald),
                ),
              if (query.length >= 2 &&
                  !allies.isSearching.value &&
                  otherMembers.isEmpty)
                Text(
                  'Aucun autre membre trouvé.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                'En acceptant, cette personne rejoindra votre quête et deviendra votre alliée.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _StakeStep extends StatelessWidget {
  const _StakeStep({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read unconditionally so the disabled build still has an observable
      // dependency; GetX otherwise rejects an Obx whose short-circuited
      // branch never touches reactive state.
      final hasStake = controller.hasStake.value;
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.outlineVariant15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: controller.paymentsEnabled ? 1 : 0.45,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENJEU OPTIONNEL',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quelle est la valeur de votre parole ?',
                          style: AppTypography.titleLg.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.paymentsEnabled ? hasStake : false,
                    onChanged: controller.paymentsEnabled
                        ? (value) => controller.hasStake.value = value
                        : null,
                    activeThumbColor: AppColors.primaryFixed,
                  ),
                ],
              ),
            ),
            if (!controller.paymentsEnabled) ...[
              const SizedBox(height: 20),
              _StakeInfo(
                icon: Icons.schedule,
                message: 'Les enjeux financiers seront bientôt disponibles.',
              ),
            ] else if (!hasStake) ...[
              const SizedBox(height: 20),
              const _StakeInfo(
                icon: Icons.info_outline,
                message:
                    'Activez cette option pour financer votre engagement en sandbox.',
              ),
            ] else ...[
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.stakeController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.displayLg.copyWith(
                        color: AppColors.primary,
                        fontSize: 40,
                      ),
                      decoration: InputDecoration(
                        hintText: '200',
                        hintStyle: AppTypography.displayLg.copyWith(
                          color: AppColors.surfaceContainerHighest,
                          fontSize: 40,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'XOF',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.surfaceBright,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _StakeInfo(
                icon: Icons.info_outline,
                message:
                    'Minimum 200 XOF. Le paiement Wave sera demandé après la création.',
              ),
              const SizedBox(height: 24),
              Text(
                'DISTRIBUTION DES FONDS',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 12),
              _DistributionOption(
                icon: Icons.groups,
                label: 'Partager entre mes alliés',
                description:
                    'Les fonds seront divisés équitablement entre vos alliés.',
                selected:
                    controller.fundsDistribution.value ==
                    FundsDistribution.allies,
                onTap: () => controller.fundsDistribution.value =
                    FundsDistribution.allies,
              ),
              const SizedBox(height: 12),
              _DistributionOption(
                icon: Icons.volunteer_activism,
                label: 'Donner à une association',
                description: 'Un don manuel sera préparé si la quête échoue.',
                selected:
                    controller.fundsDistribution.value ==
                    FundsDistribution.charity,
                onTap: () => controller.fundsDistribution.value =
                    FundsDistribution.charity,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _StakeInfo extends StatelessWidget {
  const _StakeInfo({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionOption extends StatelessWidget {
  const _DistributionOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainer,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(
            color: selected
                ? AppColors.primaryFixed
                : AppColors.outlineVariant15,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppColors.primary : AppColors.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RÉCAPITULATIF',
          style: AppTypography.displayLg.copyWith(
            color: AppColors.primary,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 32),
        Obx(() {
          final stake = controller.paymentsEnabled && controller.hasStake.value
              ? double.tryParse(controller.stakeController.text)
              : null;
          return Column(
            children: [
              _ReviewRow(
                label: 'Titre',
                value: controller.titleController.text.trim().isEmpty
                    ? '—'
                    : controller.titleController.text.trim(),
              ),
              if (controller.createForSomeoneElse.value) ...[
                const SizedBox(height: 8),
                const _ReviewRow(
                  label: 'Destinataire',
                  value: 'Invitation envoyée à l’acceptation',
                ),
              ],
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Durée',
                value: '${controller.durationController.text} jours',
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Fréquence',
                value: controller.frequency.value == QuestFrequency.daily
                    ? 'Quotidien'
                    : 'Hebdomadaire',
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Preuve requise',
                value: controller.requiresProof.value ? 'Oui' : 'Non',
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Absences tolérées',
                value:
                    '${controller.missedPeriodsAllowed} '
                    '${controller.frequency.value == QuestFrequency.daily ? 'jour(s)' : 'semaine(s)'}',
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Rattrapage après échéance',
                value:
                    '${math.max(0, int.tryParse(controller.gracePeriodText.value) ?? 0)} jour(s)',
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Enjeu',
                value: stake == null ? 'Aucun' : formatXof(stake),
                valueColor: stake == null ? null : AppColors.emerald,
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Alliés invités',
                value: controller.selectedAllyIds.isEmpty
                    ? 'Aucun'
                    : '${controller.selectedAllyIds.length} (invitation en attente)',
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value, this.valueColor});

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
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
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
