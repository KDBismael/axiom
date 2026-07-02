import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../controllers/social_controller.dart';
import '../models/ally_invitation.dart';

/// "Rejoindre la mission" — shown when responding to an ally-invite. Since
/// this app has no session distinguishing a logged-in vs. new user,
/// ACCEPTER always routes through the real Register screen (mock account
/// creation), keeping a single consistent path.
class InvitationAllyView extends StatelessWidget {
  const InvitationAllyView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    final passedInvitation = Get.arguments as AllyInvitation?;
    return Obx(() {
      final pending = controller.pendingInvitations;
      final invitation = passedInvitation ?? (pending.isEmpty ? null : pending.first);

      if (invitation == null) {
        return Scaffold(
          body: Center(
            child: Text(
              'Aucune invitation en attente.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
          ),
        );
      }

      return _InvitationScaffold(controller: controller, invitation: invitation);
    });
  }
}

class _InvitationScaffold extends StatelessWidget {
  const _InvitationScaffold({required this.controller, required this.invitation});

  final SocialController controller;
  final AllyInvitation invitation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'AXIOM',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02 * 20,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.settings, color: AppColors.primary),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVITATION FORMELLE',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'REJOINDRE LA MISSION',
                    style: AppTypography.displayLg.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(text: 'Vous avez été invité par '),
                        TextSpan(
                          text: invitation.inviterName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: ' pour être son allié de responsabilité pour la quête ',
                        ),
                        TextSpan(
                          text: '"${invitation.questTitle}"',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      invitation.roleQuote,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: AppRadii.structuralRadius,
                      border: Border.all(color: AppColors.outlineVariant15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROTOCOL_STATUS',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.outline,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SegmentedProgress(ratio: 0.5, segments: 4, height: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _IconChip(
                          icon: Icons.shield,
                          label: 'VIGILANCE',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _IconChip(
                          icon: Icons.payments,
                          label: 'RÉTRIBUTION',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'ACCEPTER LE PACTE',
                          trailingIcon: Icons.gavel,
                          onPressed: () {
                            controller.respondToInvitation(invitation.id, accepted: true);
                            Get.toNamed(AppRoutes.register);
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
                          onPressed: () {
                            controller.respondToInvitation(invitation.id, accepted: false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Invitation refusée.',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                backgroundColor: AppColors.surfaceContainerHigh,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.outlineVariant15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ENJEU ACTUEL',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatXof(invitation.stakeAmount),
                                style: AppTypography.titleLg.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DURÉE DU PACTE',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.outline,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${invitation.durationDays} JOURS',
                                style: AppTypography.titleLg.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.emerald, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(color: AppColors.outline, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
