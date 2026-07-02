import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../controllers/quest_create_controller.dart';
import '../models/quest_model.dart';

class QuestCreateView extends GetView<QuestCreateController> {
  const QuestCreateView({super.key});

  @override
  Widget build(BuildContext context) {
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
                      onTap: Get.back,
                      child: Text(
                        'QUITTER',
                        style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final step = controller.currentStep.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ÉTAPE ${(step + 1).toString().padLeft(2, '0')} — 0${QuestCreateController.stepCount}',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(QuestCreateController.stepCount, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: i == QuestCreateController.stepCount - 1 ? 0 : 4,
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
    switch (step) {
      case 0:
        return _TitleStep(controller: controller);
      case 1:
        return _DurationFrequencyStep(controller: controller);
      case 2:
        return _AlliesStep(controller: controller);
      case 3:
        return _StakeStep(controller: controller);
      default:
        return _ReviewStep(controller: controller);
    }
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
          final isLastStep = step == QuestCreateController.stepCount - 1;
          final isStakeStep = step == QuestCreateController.stakeStepIndex;
          final goToPayment = isStakeStep && controller.hasStakeAmount;
          final label = isLastStep
              ? 'LANCER LA QUÊTE'
              : goToPayment
                  ? 'CONTINUER VERS LE PAIEMENT'
                  : 'SUIVANT';
          return Row(
            children: [
              TextButton(
                onPressed: controller.previousStep,
                child: Text(
                  'RETOUR',
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  label: label,
                  trailingIcon: goToPayment ? Icons.arrow_forward : null,
                  onPressed: step == 0 && !controller.canProceedFromTitle
                      ? null
                      : () async {
                          if (isLastStep) {
                            await controller.submit();
                            Get.back();
                          } else if (goToPayment) {
                            Get.toNamed(AppRoutes.questPayment);
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
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.emerald),
            ),
          ),
          onSubmitted: (_) => controller.nextStep(),
        ),
      ],
    );
  }
}

class _DurationFrequencyStep extends StatelessWidget {
  const _DurationFrequencyStep({required this.controller});

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
        const SizedBox(height: 40),
        Text(
          'FRÉQUENCE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: [
              _FrequencyOption(
                label: 'Quotidien',
                selected: controller.frequency.value == QuestFrequency.daily,
                onTap: () => controller.frequency.value = QuestFrequency.daily,
              ),
              const SizedBox(height: 8),
              _FrequencyOption(
                label: 'Hebdomadaire',
                selected: controller.frequency.value == QuestFrequency.weekly,
                onTap: () => controller.frequency.value = QuestFrequency.weekly,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FrequencyOption extends StatelessWidget {
  const _FrequencyOption({
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
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          borderRadius: AppRadii.interactiveRadius,
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelMd.copyWith(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _AlliesStep extends StatelessWidget {
  const _AlliesStep({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVITER DES ALLIÉS',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ces alliés devront valider votre succès final.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            Obx(
              () => Text(
                '${controller.selectedAllyIds.length} SÉLECTIONNÉ',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            hintText: 'Rechercher par nom ou @pseudo',
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.surfaceBright),
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
        const SizedBox(height: 16),
        Obx(
          () => Column(
            children: [
              for (final candidate in QuestCreateController.mockCandidates) ...[
                _CandidateRow(
                  candidate: candidate,
                  selected: controller.selectedAllyIds.contains(candidate.id),
                  onTap: () => controller.toggleAlly(candidate.id),
                ),
                if (candidate != QuestCreateController.mockCandidates.last)
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final QuestCandidateAlly candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.outlineVariant15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceContainerHighest,
              child: Text(
                candidate.name[0].toUpperCase(),
                style: AppTypography.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.name,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    candidate.handle,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.emerald : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.emerald : AppColors.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StakeStep extends StatelessWidget {
  const _StakeStep({required this.controller});

  final QuestCreateController controller;

  @override
  Widget build(BuildContext context) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENJEU OPTIONNEL',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quelle est la valeur de votre parole ?',
                      style: AppTypography.titleLg.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SÉCURISÉ',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.emerald,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
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
                    hintText: '0',
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
                  style: AppTypography.titleLg.copyWith(color: AppColors.surfaceBright),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: AppRadii.interactiveRadius,
              border: Border.all(color: AppColors.outlineVariant15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primaryFixedDim, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "En cas d'échec validé par vos alliés, ce montant sera débité.",
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'DISTRIBUTION DES FONDS',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _DistributionOption(
                    icon: Icons.groups,
                    label: 'Partager entre mes alliés',
                    description: 'Les fonds seront divisés équitablement entre vos garants.',
                    selected: controller.fundsDistribution.value == FundsDistribution.allies,
                    onTap: () =>
                        controller.fundsDistribution.value = FundsDistribution.allies,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DistributionOption(
                    icon: Icons.volunteer_activism,
                    label: 'Donner à une association',
                    description: 'Un impact social positif en cas de non-respect.',
                    selected: controller.fundsDistribution.value == FundsDistribution.charity,
                    onTap: () =>
                        controller.fundsDistribution.value = FundsDistribution.charity,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(
            color: selected ? AppColors.primaryFixed : AppColors.outlineVariant15,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: selected ? AppColors.primary : AppColors.outline),
            const SizedBox(height: 12),
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
              style: AppTypography.labelMd.copyWith(color: AppColors.outline, fontSize: 11),
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
          style: AppTypography.displayLg.copyWith(color: AppColors.primary, fontSize: 40),
        ),
        const SizedBox(height: 32),
        Obx(() {
          final stake = double.tryParse(controller.stakeController.text);
          final allies = QuestCreateController.mockCandidates
              .where((c) => controller.selectedAllyIds.contains(c.id))
              .map((c) => c.name)
              .join(', ');
          return Column(
            children: [
              _ReviewRow(
                label: 'Titre',
                value: controller.titleController.text.trim().isEmpty
                    ? '—'
                    : controller.titleController.text.trim(),
              ),
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
              _ReviewRow(label: 'Alliés', value: allies.isEmpty ? 'Aucun' : allies),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Enjeu',
                value: stake == null ? 'Aucun' : formatXof(stake),
                valueColor: stake == null ? null : AppColors.emerald,
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
