import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/allies_controller.dart';

/// Confirmation screen for redeeming an ally-invitation token — reached
/// from the "paste invitation code" flow (no deep-link handling this
/// batch, per plan).
class InvitationAllyView extends StatelessWidget {
  const InvitationAllyView({super.key});

  @override
  Widget build(BuildContext context) {
    final token = Get.arguments as String;
    final controller = Get.find<AlliesController>();

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
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVITATION FORMELLE',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DEVENIR ALLIÉ',
                    style: AppTypography.displayLg.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadii.structuralRadius,
                      border: const Border(
                        left: BorderSide(color: AppColors.emerald, width: 4),
                      ),
                    ),
                    child: Text(
                      'En acceptant, vous devenez allié de responsabilité : vous pourrez être '
                      'sollicité pour valider les preuves de réussite de vos quêtes partagées.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Obx(() {
                    final error = controller.errorMessage.value;
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        error,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                      ),
                    );
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'ACCEPTER LE PACTE',
                          trailingIcon: Icons.gavel,
                          onPressed: () async {
                            await controller.redeemInvitation(token);
                            if (controller.errorMessage.value == null) Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'REFUSER',
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            await controller.declineInvitation(token);
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 14, color: AppColors.outline),
                      const SizedBox(width: 8),
                      Text(
                        'SÉCURISÉ PAR PROTOCOLE AXIOM',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
