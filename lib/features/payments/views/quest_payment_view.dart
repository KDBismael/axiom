import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../controllers/quest_payment_controller.dart';
import '../utils/transaction_fees.dart';

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
          controller.topUp != null ? 'AJOUTER UN ENJEU' : 'PAIEMENT DE LA MISE',
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
            if (controller.paymentFailed.value) {
              return _FailedState(controller: controller);
            }
            if (controller.transaction.value != null) {
              return _WaitingState(controller: controller, quest: quest);
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
        _SummaryCard(quest: quest, topUp: controller.topUp),
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
                  phoneNumber: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
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
        const Center(
          child: CircularProgressIndicator(color: AppColors.emerald),
        ),
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
        if (controller.paymentTimedOut.value) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'RÉESSAYER LE PAIEMENT',
            onPressed: () => controller.pay(),
          ),
        ],
      ],
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState({required this.controller});

  final QuestPaymentController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(
          child: Icon(Icons.error_outline, color: AppColors.error, size: 64),
        ),
        const SizedBox(height: 24),
        Text(
          'Le paiement a échoué.',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          "Wave n'a pas confirmé ce paiement. Vous pouvez réessayer.",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'RÉESSAYER LE PAIEMENT',
          onPressed: () => controller.pay(),
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
            final questId = quest?.id;
            if (questId != null) {
              Get.offNamed(AppRoutes.questDetail, arguments: questId);
            }
          },
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double? amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueStyle = emphasize
        ? AppTypography.titleLg.copyWith(color: AppColors.primary)
        : AppTypography.bodyMd.copyWith(color: AppColors.primary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        Text(amount != null ? formatXof(amount!) : '—', style: valueStyle),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.quest, this.topUp});

  final QuestModel? quest;
  final StakeTopUp? topUp;

  @override
  Widget build(BuildContext context) {
    // A top-up's amount is what's being charged right now, not the quest's
    // (possibly still-null, or not-yet-updated) total stake.
    final amount = topUp?.amountXof ?? quest?.stakeAmountXof;
    final distribution = topUp?.fundsDistribution ?? quest?.fundsDistribution;
    final fees = amount != null ? calculateTransactionFees(amount) : null;
    final total = amount != null && fees != null ? amount + fees : null;
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
            topUp != null ? 'MONTANT À AJOUTER' : 'MONTANT DE LA MISE',
            style: AppTypography.labelMd.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 8),
          Text(
            amount != null ? formatXof(amount) : '—',
            style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          _FeeRow(label: 'FRAIS DE TRANSACTION', amount: fees),
          const SizedBox(height: 8),
          _FeeRow(label: 'TOTAL À PAYER', amount: total, emphasize: true),
          const SizedBox(height: 12),
          Text(
            distribution == FundsDistribution.allies
                ? "En cas d'échec, reversé aux alliés."
                : "En cas d'échec, reversé à une association caritative.",
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
