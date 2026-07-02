import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/social_controller.dart';
import '../models/ally_validation_request.dart';

/// Full "Validations" screen — shows each friend's submitted proof (photo
/// or text) so the ally can actually judge it before approving/rejecting,
/// rather than deciding blind (which the old inline Profile row did).
class AllyValidationsView extends StatelessWidget {
  const AllyValidationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialController>();
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 64,
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
                    'Validations',
                    style: AppTypography.displayLg.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ALLIÉS EN ATTENTE DE VÉRIFICATION',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    final pending = controller.pendingValidations;
                    if (pending.isEmpty) return const _EmptyState();
                    return Column(
                      children: [
                        for (final request in pending) ...[
                          _ValidationCard(
                            request: request,
                            onApprove: () =>
                                controller.respondToValidation(request.id, approved: true),
                            onReject: () =>
                                controller.respondToValidation(request.id, approved: false),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const _EmptyState(),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationCard extends StatelessWidget {
  const _ValidationCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final AllyValidationRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceContainerHighest,
                child: Text(
                  request.friendName[0].toUpperCase(),
                  style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.friendName,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Quête : ${request.questTitle}',
                      style: AppTypography.labelMd.copyWith(color: AppColors.primaryFixed),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (request.proofType == ProofType.photo)
            _PhotoProof(caption: request.evidence)
          else
            _TextProof(quote: request.evidence),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'APPROUVER', onPressed: onApprove),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'REJETER',
                  variant: AppButtonVariant.secondary,
                  onPressed: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoProof extends StatelessWidget {
  const _PhotoProof({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadii.interactiveRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: AppColors.outline, size: 18),
              const SizedBox(width: 8),
              Text(
                'PREUVE PHOTO',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            caption,
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _TextProof extends StatelessWidget {
  const _TextProof({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppRadii.interactiveRadius,
        border: const Border(
          left: BorderSide(color: AppColors.emerald, width: 2),
        ),
      ),
      child: Text(
        '"$quote"',
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.primary,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.outlineVariant, size: 36),
          const SizedBox(height: 12),
          Text(
            'FIN DES VALIDATIONS URGENTES',
            style: AppTypography.labelMd.copyWith(color: AppColors.outlineVariant),
          ),
        ],
      ),
    );
  }
}
