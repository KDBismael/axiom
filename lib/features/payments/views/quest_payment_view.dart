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
          style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontSize: 24),
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
    if (controller.paymentTimedOut.value) {
      return _PendingState(controller: controller, quest: quest);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(child: _WavePulse()),
        const SizedBox(height: 24),
        Text(
          'En attente de confirmation du paiement…',
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

/// Shown once the client gives up polling without a spinner that makes the
/// app look stuck — the payment isn't lost or failed, GeniusPay/Wave just
/// hasn't confirmed it yet. The user is free to leave; the quest still
/// updates itself later via the webhook (or reconciliation) and a
/// notification.
class _PendingState extends StatelessWidget {
  const _PendingState({required this.controller, required this.quest});

  final QuestPaymentController controller;
  final QuestModel? quest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(
          child: Icon(Icons.hourglass_top, color: AppColors.volt, size: 64),
        ),
        const SizedBox(height: 24),
        Text(
          'Paiement en cours de traitement',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          "Wave n'a pas encore confirmé ce paiement. Vous serez notifié dès que ce sera fait.",
          textAlign: TextAlign.center,
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 24),
        AppButton(
          label: 'VÉRIFIER MAINTENANT',
          variant: AppButtonVariant.secondary,
          onPressed: controller.checkNow,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'RETOUR À LA QUÊTE',
          onPressed: () {
            final questId = quest?.id;
            if (questId != null) {
              Get.offNamed(AppRoutes.questDetail, arguments: questId);
            } else {
              Get.back();
            }
          },
        ),
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

/// Three concentric rings expanding and fading out of the Wave "W" mark,
/// staggered — the mockup's `ndRing` keyframe (scale .45→1.9, opacity .9→0).
class _WavePulse extends StatefulWidget {
  const _WavePulse();

  @override
  State<_WavePulse> createState() => _WavePulseState();
}

class _WavePulseState extends State<_WavePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final delay in [0.0, 1 / 3, 2 / 3])
                _pulseRing((_controller.value + delay) % 1.0),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.waveCyan,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'W',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pulseRing(double t) {
    final scale = 0.45 + t * (1.9 - 0.45);
    final opacity = (0.9 * (1 - t)).clamp(0.0, 0.9);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.waveCyan, width: 2),
          ),
        ),
      ),
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
        const _SuccessBurst(),
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

/// A rotated volt diamond popping in with an overshoot — the mockup's
/// `ndPop` keyframe — with a glowing volt shadow and a checkmark rotated
/// back upright inside it.
class _SuccessBurst extends StatelessWidget {
  const _SuccessBurst();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Transform.rotate(
        angle: 0.7853981633974483,
        child: Container(
          width: 90,
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.volt,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: AppColors.volt.withValues(alpha: 0.4), blurRadius: 50),
            ],
          ),
          child: Transform.rotate(
            angle: -0.7853981633974483,
            child: const Text(
              '✓',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
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
        ? const TextStyle(fontFamily: 'Unbounded', fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.volt)
        : AppTypography.bodyMd.copyWith(color: AppColors.primary);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: emphasize ? 8 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: emphasize
                ? AppTypography.bodyMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)
                : AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
          Text(amount != null ? formatXof(amount!) : '—', style: valueStyle),
        ],
      ),
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
