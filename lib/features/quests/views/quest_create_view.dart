import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_effects.dart';
import '../../payments/utils/transaction_fees.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/user_search_result.dart';
import '../controllers/quest_create_controller.dart';
import '../models/quest_model.dart';

class QuestCreateView extends GetView<QuestCreateController> {
  const QuestCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              final step = controller.currentStep.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            tooltip: 'Fermer',
                            onPressed: controller.isSubmitting.value
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                                side: const BorderSide(
                                  color: AppColors.outlineVariant,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOUVELLE QUÊTE · ÉTAPE ${step + 1}/${controller.stepCount}',
                                style: AppTypography.labelMd.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 1.54,
                                  color: AppColors.outlineMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                controller.stepTitles[step],
                                style: AppTypography.bodyMd.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: List.generate(controller.stepCount, (i) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 5,
                            margin: EdgeInsets.only(
                              right: i == controller.stepCount - 1 ? 0 : 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i <= step
                                  ? AppColors.volt
                                  : AppColors.surfaceContainerHighest,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            }),
            Expanded(
              child: Obx(
                () => SingleChildScrollView(
                  key: ValueKey(controller.currentStep.value),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: _stepBody(controller.currentStep.value),
                ),
              ),
            ),
            Obx(() {
              final error = controller.errorMessage.value;
              if (error == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  error,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                ),
              );
            }),
            _Footer(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(int step) => switch (step) {
    0 => _TypeStep(controller: controller),
    1 => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleStep(controller: controller),
        const SizedBox(height: 16),
        _ScheduleRulesStep(controller: controller),
        if (controller.createForSomeoneElse.value) ...[
          const SizedBox(height: 24),
          _InviteeStep(controller: controller),
        ],
      ],
    ),
    2 => _AlliesStep(controller: controller),
    3 when !controller.isCollective.value => _StakeStep(controller: controller),
    _ => _ReviewStep(controller: controller),
  };
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E1E23))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Obx(() {
          final step = controller.currentStep.value;
          final isLastStep = step == controller.stepCount - 1;
          final amount = controller.effectiveStakeAmount;
          final label = !isLastStep
              ? 'CONTINUER'
              : amount > 0
              ? 'PAYER ${_amount(amount + calculateTransactionFees(amount))} XOF'
              : 'LANCER LA QUÊTE';
          return Row(
            children: [
              if (step > 0)
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Semantics(
                    button: true,
                    label: 'Retour',
                    child: AppPressable(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineVariantStrong),
                      color: AppColors.surfaceContainerLow,
                      shadowColor: const Color(0xFF0A0A0C),
                      shadowThickness: 4,
                      onTap: controller.isSubmitting.value
                          ? null
                          : controller.previousStep,
                      child: const Center(
                        child: Text(
                          '←',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (step > 0) const SizedBox(width: 10),
              Expanded(
                child: _ContinueButton(
                  label: label,
                  loading: controller.isSubmitting.value,
                  onPressed:
                      !controller.canProceed || controller.isSubmitting.value
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
                              } else if (controller.isCollective.value) {
                                Get.snackbar(
                                  'Quête collective créée',
                                  controller.selectedAllyIds.isEmpty
                                      ? 'Votre quête a été créée.'
                                      : 'Vos invitations ont été envoyées. Vos coéquipiers rejoindront dès qu\'ils accepteront.',
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

TextStyle get _eyebrow => AppTypography.labelMd.copyWith(
  fontSize: 11,
  letterSpacing: 1.54,
  fontWeight: FontWeight.w400,
  color: AppColors.outlineMuted,
);
TextStyle get _heading => AppTypography.headlineMd.copyWith(
  fontSize: 24,
  height: 1.15,
  letterSpacing: 0,
  color: AppColors.primary,
);
String _amount(num value) => value
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]} ');
BoxDecoration _panel({double radius = 16}) => BoxDecoration(
  color: AppColors.surfaceContainerLow,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.outlineVariant),
);
InputDecoration _input({String? hint}) => InputDecoration(
  hintText: hint,
  hintStyle: AppTypography.bodyMd.copyWith(
    fontSize: 15,
    color: AppColors.outlineMuted,
    height: 1.45,
  ),
  filled: true,
  fillColor: AppColors.surfaceContainerLow,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.outlineVariantStrong),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.outlineVariantStrong),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.volt),
  ),
);

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    child: SizedBox(
      height: 58,
      child: AppPressable(
        borderRadius: BorderRadius.circular(16),
        color: onPressed == null
            ? AppColors.surfaceContainerHighest
            : AppColors.volt,
        shadowColor: onPressed == null
            ? const Color(0xFF0A0A0C)
            : AppColors.voltShadow,
        onTap: onPressed,
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.outline,
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLg.copyWith(
                    fontSize: 13,
                    letterSpacing: 0.65,
                    color: onPressed == null
                        ? AppColors.outlineFaint
                        : AppColors.onPrimary,
                  ),
                ),
        ),
      ),
    ),
  );
}

class _TitleStep extends StatelessWidget {
  const _TitleStep({required this.controller});
  final QuestCreateController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('TITRE *', style: _eyebrow),
      const SizedBox(height: 8),
      SizedBox(
        height: 56,
        child: TextField(
          controller: controller.titleController,
          style: AppTypography.bodyMd.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          decoration: _input(hint: 'Méditer 10 minutes'),
        ),
      ),
      const SizedBox(height: 16),
      Text("POURQUOI C'EST IMPORTANT *", style: _eyebrow),
      const SizedBox(height: 8),
      TextField(
        controller: controller.descriptionController,
        minLines: 2,
        maxLines: 5,
        style: AppTypography.bodyMd.copyWith(
          fontSize: 15,
          height: 1.45,
          color: AppColors.primary,
        ),
        decoration: _input(
          hint: "Ce qui te fera tenir le jour où tu n'en as pas envie.",
        ),
      ),
    ],
  );
}

class _TypeStep extends StatelessWidget {
  const _TypeStep({required this.controller});
  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final collective = controller.isCollective.value;
    final sponsored = controller.createForSomeoneElse.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quel type de défi ?',
          style: AppTypography.headlineMd.copyWith(
            fontSize: 24,
            height: 1.15,
            letterSpacing: 0,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        _QuestTypeTile(
          symbol: '1',
          iconColor: AppColors.volt,
          label: 'Solo',
          description: 'Tu le fais, tu en es responsable.',
          selected: !collective && !sponsored,
          onTap: () {
            controller.isCollective.value = false;
            controller.createForSomeoneElse.value = false;
            controller.selectedInviteeId.value = null;
            controller.selectedInviteeName.value = null;
          },
        ),
        const SizedBox(height: 16),
        _QuestTypeTile(
          symbol: '→',
          iconColor: const Color(0xFF4FC3F7),
          label: 'Parrainer',
          description:
              "Tu crées et finances une quête pour un ami. Il doit l'accepter.",
          selected: sponsored,
          onTap: () {
            controller.createForSomeoneElse.value = true;
            controller.isCollective.value = false;
          },
        ),
        const SizedBox(height: 16),
        _QuestTypeTile(
          symbol: '4',
          iconColor: AppColors.emberLight,
          label: 'Collective',
          description:
              'Même quête, chacun sa piste. Tout le monde juge tout le monde.',
          selected: collective,
          onTap: () {
            controller.isCollective.value = true;
            controller.createForSomeoneElse.value = false;
            controller.selectedInviteeId.value = null;
            controller.selectedInviteeName.value = null;
          },
        ),
      ],
    );
  });
}

class _QuestTypeTile extends StatelessWidget {
  const _QuestTypeTile({
    required this.symbol,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final Color iconColor;
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
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? AppColors.voltTint(0.07)
              : AppColors.surfaceContainerLow,
          border: Border.all(
            color: selected ? AppColors.volt : AppColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                symbol,
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.outline,
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

class _ScheduleRulesStep extends StatelessWidget {
  const _ScheduleRulesStep({required this.controller});
  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final daily = controller.frequency.value == QuestFrequency.daily;
    final missed = controller.missedPeriodsAllowed;
    final maxMissed = math.max(0, controller.expectedPeriods - 1);
    // Read both values while Obx is building. LayoutBuilder invokes its
    // builder later, outside GetX's dependency tracking scope.
    final durationDays = controller.durationDays;
    final targetPerPeriod = controller.targetPerPeriod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FRÉQUENCE', style: _eyebrow),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: _panel(radius: 14),
          child: Row(
            children: [
              for (final frequency in [
                QuestFrequency.daily,
                QuestFrequency.weekly,
              ])
                Expanded(
                  child: _FrequencyButton(
                    label: frequency == QuestFrequency.daily
                        ? 'Quotidienne'
                        : 'Hebdomadaire',
                    selected: controller.frequency.value == frequency,
                    onTap: () => controller.frequency.value = frequency,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final duration = _Counter(
              label: 'Durée',
              value: '$durationDays',
              unit: 'jours',
              onMinus: () => controller.adjustDuration(-1),
              onPlus: () => controller.adjustDuration(1),
            );
            final target = _Counter(
              label: 'Objectif',
              value: '$targetPerPeriod×',
              unit: daily ? 'par jour' : 'par semaine',
              onMinus: () => controller.adjustTarget(-1),
              onPlus: () => controller.adjustTarget(1),
            );
            if (constraints.maxWidth < 330) {
              return Column(
                children: [duration, const SizedBox(height: 10), target],
              );
            }
            return Row(
              children: [
                Expanded(child: duration),
                const SizedBox(width: 10),
                Expanded(child: target),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _panel(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Absences tolérées',
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '$missed',
                    style: AppTypography.titleLg.copyWith(
                      fontSize: 15,
                      color: AppColors.volt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    padding: EdgeInsets.zero,
                    value: missed.toDouble(),
                    min: 0,
                    max: math.max(1, maxMissed).toDouble(),
                    divisions: math.max(1, maxMissed),
                    activeColor: AppColors.volt,
                    inactiveColor: AppColors.surfaceBright,
                    onChanged: maxMissed == 0
                        ? null
                        : (value) =>
                              controller.setMissedPeriodsAllowed(value.round()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$missed ${daily ? 'jours' : 'semaines'} sans conséquence · seuil de réussite ${controller.successThresholdPercent.value} %',
                style: AppTypography.bodyMd.copyWith(
                  fontSize: 12.5,
                  color: AppColors.outlineMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: _panel(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preuve obligatoire',
                      style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Chaque check-in validé par un allié',
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 12.5,
                        color: AppColors.outlineMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                label: 'Preuve obligatoire',
                toggled: controller.requiresProof.value,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => controller.requiresProof.toggle(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: controller.requiresProof.value
                          ? AppColors.volt
                          : AppColors.surfaceBright,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: controller.requiresProof.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.onPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  });
}

class _FrequencyButton extends StatelessWidget {
  const _FrequencyButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onPrimary : AppColors.outline,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
  });
  final String label, value, unit;
  final VoidCallback onMinus, onPlus;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _panel(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            fontSize: 12,
            color: AppColors.outlineMuted,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _counterButton('−', onMinus),
            Flexible(
              child: Column(
                children: [
                  Text(
                    value,
                    style: AppTypography.titleLg.copyWith(
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    unit,
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 11,
                      color: AppColors.outlineMuted,
                    ),
                  ),
                ],
              ),
            ),
            _counterButton('+', onPlus),
          ],
        ),
      ],
    ),
  );
  Widget _counterButton(String symbol, VoidCallback onTap) => Semantics(
    button: true,
    label: '${symbol == '+' ? 'Augmenter' : 'Diminuer'} $label',
    child: Material(
      color: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(color: AppColors.outlineVariantStrong),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 18, color: AppColors.primary),
            ),
          ),
        ),
      ),
    ),
  );
}

class _InviteeStep extends StatelessWidget {
  const _InviteeStep({required this.controller});
  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('DESTINATAIRE', style: _eyebrow),
      const SizedBox(height: 8),
      Text(
        'Choisis la personne qui recevra cette quête. Elle devra accepter ton invitation.',
        style: AppTypography.bodyMd.copyWith(
          fontSize: 13,
          color: AppColors.outlineMuted,
          height: 1.4,
        ),
      ),
      const SizedBox(height: 12),
      Obx(() {
        final name = controller.selectedInviteeName.value;
        return Material(
          color: name == null
              ? AppColors.surfaceContainerLow
              : AppColors.voltTint(0.07),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: name == null ? AppColors.outlineVariant : AppColors.volt,
              width: 1.5,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _RecipientSearchPage(controller: controller),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    name == null
                        ? Icons.person_search_outlined
                        : Icons.check_circle,
                    size: 24,
                    color: name == null
                        ? AppColors.outlineMuted
                        : AppColors.volt,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name ?? 'Choisir un destinataire',
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    name == null ? 'Rechercher' : 'Modifier',
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 12,
                      color: AppColors.outlineMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ],
  );
}

class _RecipientSearchPage extends StatefulWidget {
  const _RecipientSearchPage({required this.controller});
  final QuestCreateController controller;

  @override
  State<_RecipientSearchPage> createState() => _RecipientSearchPageState();
}

class _RecipientSearchPageState extends State<_RecipientSearchPage> {
  @override
  void initState() {
    super.initState();
    final allies = Get.find<AlliesController>();
    allies.clearSearch();
    final query = widget.controller.inviteeSearchController.text.trim();
    if (query.length >= 2) allies.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final allies = Get.find<AlliesController>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: 'Retour',
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                          side: const BorderSide(
                            color: AppColors.outlineVariant,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rechercher un destinataire',
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: widget.controller.inviteeSearchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: allies.search,
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                decoration: _input(hint: 'Nom ou prénom').copyWith(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.outlineMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                final query = allies.searchQuery.value;
                final members = query.length < 2
                    ? const <UserSearchResult>[]
                    : allies.searchResults;
                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    if (query.length < 2)
                      Text(
                        'Saisis au moins deux lettres pour trouver un membre.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.outlineMuted,
                        ),
                      ),
                    for (final user in members) ...[
                      _AllyOption(
                        name: '${user.firstName} ${user.lastName}'.trim(),
                        selected:
                            widget.controller.selectedInviteeId.value ==
                            user.id,
                        onTap: () {
                          widget.controller.setInvitee(
                            user.id,
                            name: '${user.firstName} ${user.lastName}'.trim(),
                          );
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (query.length >= 2 && allies.isSearching.value)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.volt),
                      ),
                    if (query.length >= 2 &&
                        !allies.isSearching.value &&
                        members.isEmpty)
                      Text(
                        'Aucun membre trouvé.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.outlineMuted,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
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
    final allies = Get.find<AlliesController>();
    allies.clearSearch();
    final query = widget.controller.allySearchController.text.trim();
    if (query.length >= 2) allies.search(query);
  }

  @override
  Widget build(BuildContext context) {
    final allies = Get.find<AlliesController>();
    final collective = widget.controller.isCollective.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          collective ? 'Avec qui tu te lances ?' : 'Qui sera à tes côtés ?',
          style: _heading,
        ),
        const SizedBox(height: 8),
        Text(
          collective
              ? 'Chaque membre suit sa propre progression et valide les preuves des autres. Une invitation lui sera envoyée.'
              : 'Tes alliés valident tes preuves et t’aident à tenir ton engagement. Ils recevront une invitation.',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.outlineMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Text('RECHERCHER UN MEMBRE', style: _eyebrow),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller.allySearchController,
          onChanged: allies.search,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: _input(hint: 'Nom ou prénom').copyWith(
            prefixIcon: const Icon(Icons.search, color: AppColors.outlineMuted),
          ),
        ),
        const SizedBox(height: 20),
        Obx(() {
          final selectedIds = widget.controller.selectedAllyIds.toSet();
          final selectedNames = widget.controller.selectedAllyNames;
          final allyIds = allies.allies.map((ally) => ally.id).toSet();
          final query = allies.searchQuery.value;
          final otherMembers = query.length < 2
              ? const <UserSearchResult>[]
              : allies.searchResults
                    .where(
                      (user) =>
                          !allyIds.contains(user.id) &&
                          !selectedIds.contains(user.id),
                    )
                    .toList();
          final availableAllies = allies.allies
              .where((ally) => !selectedIds.contains(ally.id))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedIds.isNotEmpty) ...[
                Text(
                  'SÉLECTIONNÉS · ${selectedIds.length}',
                  style: _eyebrow.copyWith(color: AppColors.volt),
                ),
                const SizedBox(height: 12),
                for (final id in selectedIds) ...[
                  _AllyOption(
                    name: selectedNames[id] ?? id,
                    selected: true,
                    onTap: () => widget.controller.toggleAlly(id),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
              ],
              if (availableAllies.isNotEmpty) ...[
                Text('VOS ALLIÉS', style: _eyebrow),
                const SizedBox(height: 12),
                for (final ally in availableAllies) ...[
                  _AllyOption(
                    name: '${ally.firstName} ${ally.lastName}'.trim(),
                    selected: false,
                    onTap: () => widget.controller.toggleAlly(
                      ally.id,
                      name: '${ally.firstName} ${ally.lastName}'.trim(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (otherMembers.isNotEmpty) ...[
                if (availableAllies.isNotEmpty) const SizedBox(height: 12),
                Text('AUTRES MEMBRES', style: _eyebrow),
                const SizedBox(height: 12),
                for (final user in otherMembers) ...[
                  _AllyOption(
                    name: '${user.firstName} ${user.lastName}'.trim(),
                    selected: false,
                    onTap: () => widget.controller.toggleAlly(
                      user.id,
                      name: '${user.firstName} ${user.lastName}'.trim(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              if (query.length >= 2 && allies.isSearching.value)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.volt),
                  ),
                ),
              if (query.length >= 2 &&
                  !allies.isSearching.value &&
                  otherMembers.isEmpty &&
                  !allies.searchResults.any(
                    (user) => selectedIds.contains(user.id),
                  ))
                Text(
                  'Aucun membre trouvé pour cette recherche.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outlineMuted,
                  ),
                ),
              if (selectedIds.isEmpty &&
                  availableAllies.isEmpty &&
                  query.length < 2)
                Text(
                  'Tu peux continuer sans invitation et en ajouter plus tard.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.outlineMuted,
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}

class _AllyOption extends StatelessWidget {
  const _AllyOption({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return Material(
      color: selected
          ? AppColors.voltTint(0.07)
          : AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.volt : AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.volt
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  initials,
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.onPrimary : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.add_circle_outline,
                size: 22,
                color: selected ? AppColors.volt : AppColors.outlineMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StakeStep extends StatelessWidget {
  const _StakeStep({required this.controller});
  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final amount = controller.effectiveStakeAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Combien tu mets en jeu ?', style: _heading),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2210),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF2F3F14)),
          ),
          child: Column(
            children: [
              Text(
                _amount(amount),
                style: AppTypography.displayLg.copyWith(
                  fontSize: 40,
                  letterSpacing: 0,
                  color: AppColors.volt,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'XOF',
                style: _eyebrow.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.68,
                  color: const Color(0xFFA9CF4A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 48,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (final preset in [0, 2000, 5000, 10000, 25000, 50000])
              _StakePreset(
                label: preset == 0 ? 'Aucun' : _amount(preset),
                selected: amount == preset,
                onTap: preset == 0 || controller.paymentsEnabled
                    ? () => controller.selectStake(preset)
                    : null,
              ),
          ],
        ),
        if (!controller.paymentsEnabled) ...[
          const SizedBox(height: 16),
          Text(
            'Les enjeux financiers seront bientôt disponibles.',
            style: AppTypography.bodyMd.copyWith(
              fontSize: 12.5,
              color: AppColors.outlineMuted,
            ),
          ),
        ],
        if (amount > 0) ...[
          const SizedBox(height: 20),
          Text("SI TU ÉCHOUES, L'ENJEU VA…", style: _eyebrow),
          const SizedBox(height: 16),
          _DistributionOption(
            label: 'Partagé entre mes alliés',
            description: 'À parts égales entre les alliés qui ont accepté',
            selected:
                controller.fundsDistribution.value == FundsDistribution.allies,
            onTap: () =>
                controller.fundsDistribution.value = FundsDistribution.allies,
          ),
          const SizedBox(height: 16),
          _DistributionOption(
            label: 'Donné à une association',
            description: 'Un don manuel sera préparé si la quête échoue.',
            selected:
                controller.fundsDistribution.value == FundsDistribution.charity,
            onTap: () =>
                controller.fundsDistribution.value = FundsDistribution.charity,
          ),
        ],
      ],
    );
  });
}

class _StakePreset extends StatelessWidget {
  const _StakePreset({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: Material(
      color: selected ? AppColors.voltTint(0.1) : AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: selected ? AppColors.volt : AppColors.outlineVariantStrong,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Center(
          child: Text(
            label,
            style: _eyebrow.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              color: onTap == null
                  ? AppColors.outlineFaint
                  : selected
                  ? AppColors.volt
                  : const Color(0xFFD8D8DE),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DistributionOption extends StatelessWidget {
  const _DistributionOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final String label, description;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected
          ? AppColors.voltTint(0.07)
          : AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.volt : AppColors.outlineVariantStrong,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.volt
                        : AppColors.outlineVariantStrong,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.volt : Colors.transparent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 12.5,
                        color: AppColors.outlineMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.controller});
  final QuestCreateController controller;
  @override
  Widget build(BuildContext context) => Obx(() {
    final daily = controller.frequency.value == QuestFrequency.daily;
    final stake = controller.effectiveStakeAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Prêt·e à t'engager ?", style: _heading),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _panel(radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.isCollective.value
                    ? 'QUÊTE COLLECTIVE'
                    : controller.createForSomeoneElse.value
                    ? 'QUÊTE PARRAINÉE'
                    : 'QUÊTE SOLO',
                style: _eyebrow.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 1.47,
                  color: AppColors.volt,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                controller.titleText.value.trim(),
                style: _heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: const Color(0xFF1E1E23)),
              _ReviewRow(
                label: 'Fréquence',
                value:
                    "${daily ? 'Quotidienne' : 'Hebdomadaire'} · ${controller.targetPerPeriod}× par ${daily ? 'jour' : 'semaine'}",
              ),
              _ReviewRow(
                label: 'Durée',
                value: '${controller.durationDays} jours',
              ),
              _ReviewRow(
                label: 'Absences tolérées',
                value: '${controller.missedPeriodsAllowed}',
              ),
              _ReviewRow(
                label: 'Preuve',
                value: controller.requiresProof.value
                    ? 'Obligatoire'
                    : 'Facultative',
              ),
              _ReviewRow(
                label: 'Risque',
                value: switch (controller.riskLevel) {
                  QuestRiskLevel.low => 'FAIBLE',
                  QuestRiskLevel.medium => 'MOYEN',
                  QuestRiskLevel.high => 'ÉLEVÉ',
                },
              ),
              _ReviewRow(
                label: 'Enjeu',
                value: stake > 0 ? '${_amount(stake)} XOF' : 'Aucun',
              ),
              if (stake > 0)
                _ReviewRow(
                  label: 'Si échec',
                  value:
                      controller.fundsDistribution.value ==
                          FundsDistribution.allies
                      ? 'Aux alliés'
                      : 'À une association',
                ),
              if (controller.selectedAllyIds.isNotEmpty)
                _ReviewRow(
                  label: controller.isCollective.value
                      ? 'Membres invités'
                      : 'Alliés invités',
                  value: '${controller.selectedAllyIds.length}',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Les règles sont figées une fois la quête lancée. Seuls le titre et la description restent modifiables.',
          style: AppTypography.bodyMd.copyWith(
            fontSize: 12.5,
            height: 1.5,
            color: AppColors.outlineMuted,
          ),
        ),
      ],
    );
  });
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF1E1E23))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outlineMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}
