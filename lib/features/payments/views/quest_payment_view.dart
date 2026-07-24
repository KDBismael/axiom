import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../controllers/quest_payment_controller.dart';

class QuestPaymentView extends GetView<QuestPaymentController> {
  const QuestPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final quest = Get.find<QuestListController>().findById(controller.questId);
    final phoneController = TextEditingController(
      text: Get.find<AuthController>().user.value?.phone ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Text(
          'PAIEMENT DE LA MISE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.paymentSucceeded.value) {
              return _SuccessState(quest: quest);
            }
            if (controller.transaction.value != null) {
              return _WaitingState(
                controller: controller,
                quest: quest,
              );
            }
            return _InitialState(
              controller: controller,
              quest: quest,
              phoneController: phoneController,
            );
          }),
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState({
    required this.controller,
    required this.quest,
    required this.phoneController,
  });

  final QuestPaymentController controller;
  final QuestModel? quest;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quest?.title ?? '',
          style: AppTypography.displayLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        _SummaryCard(quest: quest),
        const SizedBox(height: 24),
        Text(
          'NUMÉRO WAVE',
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: const InputDecoration(
            hintText: '+225 07 00 00 00 00',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        if (controller.errorMessage.value != null) ...[
          Text(
            controller.errorMessage.value!,
            style: AppTypography.bodyMd.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 16),
        ],
        AppButton(
          label: 'PAYER AVEC WAVE',
          leadingIcon: Icons.payments,
          loading: controller.isLoading.value,
          onPressed: controller.isLoading.value
              ? null
              : () => controller.pay(
                    phoneNumber:
                        phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  ),
        ),
      ],
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({required this.controller, required this.quest});

  final QuestPaymentController controller;
  final QuestModel? quest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
        const SizedBox(height: 24),
        Text(
          controller.paymentTimedOut.value
              ? "Nous n'avons pas encore reçu la confirmation de Wave."
              : 'En attente de confirmation du paiement…',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          "Si vous avez déjà payé, patientez quelques secondes ou vérifiez manuellement.",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'VÉRIFIER',
          variant: AppButtonVariant.secondary,
          onPressed: controller.checkNow,
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.quest});

  final QuestModel? quest;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, color: AppColors.emerald, size: 64),
        const SizedBox(height: 24),
        Text(
          'Paiement confirmé !',
          style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Votre quête est maintenant active.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'VOIR LA QUÊTE',
          onPressed: () {
            if (quest != null) Get.back(result: true);
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.quest});

  final QuestModel? quest;

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
          Text(
            'MONTANT DE LA MISE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 8),
          Text(
            quest?.stakeAmountXof != null ? formatXof(quest!.stakeAmountXof!) : '—',
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            quest?.fundsDistribution == FundsDistribution.allies
                ? "En cas d'échec, reversé aux alliés."
                : "En cas d'échec, reversé à une association caritative.",
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
