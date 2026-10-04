import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../controllers/quest_payment_controller.dart';
import '../utils/transaction_fees.dart';

String _formattedXof(double amount) => amount
    .toStringAsFixed(0)
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]} ');

String _maskedPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return phone;
  final countryLength = phone.trim().startsWith('+') && digits.length > 10
      ? digits.length - 10
      : 0;
  final country = countryLength > 0
      ? '+${digits.substring(0, countryLength)} '
      : '';
  final local = digits.length - countryLength > 4
      ? '${digits.substring(countryLength, countryLength + 2)} '
      : '';
  return '$country$local••• ${digits.substring(digits.length - 4, digits.length - 2)} '
      '${digits.substring(digits.length - 2)}';
}

class QuestPaymentView extends StatefulWidget {
  const QuestPaymentView({super.key});

  @override
  State<QuestPaymentView> createState() => _QuestPaymentViewState();
}

class _QuestPaymentViewState extends State<QuestPaymentView> {
  late final TextEditingController _phoneController;
  bool _editingPhone = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: Get.find<AuthController>().user.value?.phone ?? '',
    );
    _editingPhone = _phoneController.text.trim().isEmpty;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestPaymentController>();
    final quest = Get.find<QuestListController>().findById(controller.questId);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Material(
                      color: AppColors.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: const BorderSide(color: AppColors.outlineVariant),
                      ),
                      child: InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(13),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.topUp != null
                          ? 'AJOUTER UN ENJEU'
                          : "PAIEMENT DE L'ENJEU",
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.54,
                        color: AppColors.outlineMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.paymentSucceeded.value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SuccessState(quest: quest),
                  );
                }
                if (controller.paymentFailed.value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FailedState(controller: controller),
                  );
                }
                if (controller.transaction.value != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WaitingState(
                      controller: controller,
                      quest: quest,
                      timedOut: controller.paymentTimedOut.value,
                    ),
                  );
                }
                return _InitialState(
                  controller: controller,
                  quest: quest,
                  phoneController: _phoneController,
                  isLoading: controller.isLoading.value,
                  errorMessage: controller.errorMessage.value,
                  editingPhone: _editingPhone,
                  onEditPhone: () => setState(() => _editingPhone = true),
                  onSavePhone: () => setState(() => _editingPhone = false),
                );
              }),
            ),
          ],
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
    required this.isLoading,
    required this.errorMessage,
    required this.editingPhone,
    required this.onEditPhone,
    required this.onSavePhone,
  });

  final QuestPaymentController controller;
  final QuestModel? quest;
  final TextEditingController phoneController;
  final bool isLoading;
  final String? errorMessage;
  final bool editingPhone;
  final VoidCallback onEditPhone;
  final VoidCallback onSavePhone;

  @override
  Widget build(BuildContext context) {
    final amount = controller.topUp?.amountXof ?? quest?.stakeAmountXof;
    final total = amount == null
        ? null
        : amount + calculateTransactionFees(amount);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vérifie avant de payer',
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 24,
                    height: 1.15,
                    letterSpacing: 0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryCard(quest: quest, topUp: controller.topUp),
                const SizedBox(height: 16),
                _WavePhoneCard(
                  phoneController: phoneController,
                  editing: editingPhone,
                  onEdit: onEditPhone,
                  onSave: onSavePhone,
                ),
                const SizedBox(height: 16),
                Text(
                  'Remboursé si tu réussis. Frais non remboursables. '
                  'Tu seras redirigé·e vers Wave pour confirmer.',
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.outlineMuted,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF1E1E23))),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: AppPressable(
              borderRadius: BorderRadius.circular(16),
              color: isLoading || total == null
                  ? AppColors.surfaceContainerHighest
                  : AppColors.volt,
              shadowColor: isLoading || total == null
                  ? const Color(0xFF0A0A0C)
                  : AppColors.voltShadow,
              onTap: isLoading || total == null
                  ? null
                  : () => controller.pay(
                      phoneNumber: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                    ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.outline,
                        ),
                      )
                    : Text(
                        total == null
                            ? 'MONTANT INDISPONIBLE'
                            : 'CONFIRMER · ${_formattedXof(total)} XOF',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLg.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.65,
                          color: total == null
                              ? AppColors.outlineFaint
                              : AppColors.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WavePhoneCard extends StatelessWidget {
  const _WavePhoneCard({
    required this.phoneController,
    required this.editing,
    required this.onEdit,
    required this.onSave,
  });

  final TextEditingController phoneController;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.waveBlue, width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.waveCyan,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            'W',
            style: AppTypography.titleLg.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wave',
                style: AppTypography.bodyMd.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              if (editing)
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Numéro Wave',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => onSave(),
                )
              else
                Text(
                  _maskedPhone(phoneController.text),
                  style: AppTypography.bodyMd.copyWith(
                    fontSize: 12.5,
                    color: AppColors.outlineMuted,
                  ),
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: editing ? onSave : onEdit,
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            editing ? 'Valider' : 'Modifier',
            style: AppTypography.bodyMd.copyWith(
              fontSize: 12,
              color: AppColors.outlineMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({
    required this.controller,
    required this.quest,
    required this.timedOut,
  });

  final QuestPaymentController controller;
  final QuestModel? quest;
  final bool timedOut;

  @override
  Widget build(BuildContext context) {
    if (timedOut) {
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

class _WavePulseState extends State<_WavePulse>
    with SingleTickerProviderStateMixin {
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
              BoxShadow(
                color: AppColors.volt.withValues(alpha: 0.4),
                blurRadius: 50,
              ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.quest, this.topUp});

  final QuestModel? quest;
  final StakeTopUp? topUp;

  @override
  Widget build(BuildContext context) {
    final amount = topUp?.amountXof ?? quest?.stakeAmountXof;
    final fees = amount == null ? null : calculateTransactionFees(amount);
    final total = amount == null || fees == null ? null : amount + fees;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          _amountRow(topUp == null ? 'Enjeu' : 'Enjeu ajouté', amount),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Frais de transaction',
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 14.5,
                      color: AppColors.outline,
                    ),
                  ),
                ),
                Text(
                  fees == null ? '—' : '${_formattedXof(fees)} XOF',
                  style: const TextStyle(
                    fontFamily: 'Geist Mono',
                    fontSize: 14.5,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(
            painter: _DashedDividerPainter(),
            child: const SizedBox(width: double.infinity, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Total',
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    total == null ? '—' : '${_formattedXof(total)} XOF',
                    textAlign: TextAlign.right,
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 24,
                      letterSpacing: 0,
                      color: AppColors.volt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              fontSize: 14.5,
              color: AppColors.outline,
            ),
          ),
        ),
        Text(
          value == null ? '—' : '${_formattedXof(value)} XOF',
          style: const TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: 14.5,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

class _DashedDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariantStrong
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + 4).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) => false;
}
