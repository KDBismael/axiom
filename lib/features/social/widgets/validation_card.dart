import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../profile/widgets/authenticated_avatar_image.dart';
import '../../quests/models/check_in_model.dart';
import '../models/ally_validation_request.dart';

/// A validation that's already been decided — read-only version of
/// [ValidationCard], showing the outcome badge instead of action buttons.
/// Shared by the notification deep-link screen and the profile's history list.
class DecidedValidationCard extends StatelessWidget {
  const DecidedValidationCard({super.key, required this.request});

  final AllyValidationRequest request;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (request.status) {
      ValidationDecisionStatus.approved => ('APPROUVÉE', AppColors.emerald),
      ValidationDecisionStatus.rejected => ('REJETÉE', AppColors.error),
      ValidationDecisionStatus.cancelled => ('ANNULÉE', AppColors.outline),
      ValidationDecisionStatus.pending => ('', AppColors.outline),
    };
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
              Expanded(
                child: Text(
                  'Quête : ${request.questTitle}',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadii.interactiveRadius,
                ),
                child: Text(
                  label,
                  style: AppTypography.labelMd.copyWith(color: color, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (request.proofType == ProofType.text)
            TextProof(quote: request.textContent ?? '')
          else
            FileProof(validationId: request.id, proofType: request.proofType),
        ],
      ),
    );
  }
}

/// A single ally's submitted proof (photo, video, or text) with
/// Approve/Reject actions — shared by the full validations list and the
/// single-item notification deep-link screen.
class ValidationCard extends StatelessWidget {
  const ValidationCard({
    super.key,
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
          Text(
            'Quête : ${request.questTitle}',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          if (request.proofType == ProofType.text)
            TextProof(quote: request.textContent ?? '')
          else
            FileProof(validationId: request.id, proofType: request.proofType),
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

class FileProof extends StatelessWidget {
  const FileProof({super.key, required this.validationId, required this.proofType});

  final String validationId;
  final ProofType proofType;

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
              Icon(
                proofType == ProofType.video ? Icons.videocam_outlined : Icons.image_outlined,
                color: AppColors.outline,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                proofType == ProofType.video ? 'PREUVE VIDÉO' : 'PREUVE PHOTO',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadii.interactiveRadius,
            child: AuthenticatedAvatarImage(
              avatarUrl: '/validations/$validationId/evidence-file',
              size: 160,
            ),
          ),
        ],
      ),
    );
  }
}

class TextProof extends StatelessWidget {
  const TextProof({super.key, required this.quote});

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
