import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/media/evidence_thumbnail.dart';
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadii.interactiveRadius,
                ),
                child: Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (request.proofType == ProofType.text)
            TextProof(quote: request.textContent ?? '')
          else
            FileProof(
              validationId: request.id,
              proofType: request.proofType,
              photoCount: request.fileIds.isEmpty ? 1 : request.fileIds.length,
            ),
        ],
      ),
    );
  }
}

/// Validates the comment attached to an approve/reject decision: optional
/// when approving, but required (non-blank) when rejecting, so a rejection
/// always comes with a reason for the quest owner. Returns the French error
/// message to show, or null when the comment is acceptable.
String? validateDecisionComment({
  required bool approved,
  required String comment,
}) {
  if (approved) return null;
  return comment.trim().isEmpty
      ? 'Un commentaire est requis pour justifier un rejet.'
      : null;
}

/// A single ally's submitted proof (photo, video, or text) with
/// Approve/Reject actions — shared by the full validations list and the
/// single-item notification deep-link screen.
class ValidationCard extends StatefulWidget {
  const ValidationCard({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final AllyValidationRequest request;
  final void Function(String? comment) onApprove;
  final void Function(String comment) onReject;

  @override
  State<ValidationCard> createState() => _ValidationCardState();
}

class _ValidationCardState extends State<ValidationCard> {
  final _commentController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleApprove() {
    final comment = _commentController.text.trim();
    widget.onApprove(comment.isEmpty ? null : comment);
  }

  void _handleReject() {
    final comment = _commentController.text.trim();
    final error = validateDecisionComment(approved: false, comment: comment);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    widget.onReject(comment);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
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
            FileProof(
              validationId: request.id,
              proofType: request.proofType,
              photoCount: request.fileIds.isEmpty ? 1 : request.fileIds.length,
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _commentController,
            maxLines: 4,
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            decoration: InputDecoration(
              hintText:
                  'Commentaire (optionnel pour approuver, requis pour rejeter)...',
              hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.outlineVariant,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: AppRadii.structuralRadius,
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.structuralRadius,
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.primaryFixed),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AppTypography.bodyMd.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(label: 'APPROUVER', onPressed: _handleApprove),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'REJETER',
                  variant: AppButtonVariant.secondary,
                  onPressed: _handleReject,
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
  const FileProof({
    super.key,
    required this.validationId,
    required this.proofType,
    this.photoCount = 1,
  });

  final String validationId;
  final ProofType proofType;

  /// Number of photos to render for a photo proof (up to 3); ignored for
  /// video, which is always a single file.
  final int photoCount;

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
                proofType == ProofType.video
                    ? Icons.videocam_outlined
                    : Icons.image_outlined,
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
          if (proofType == ProofType.video)
            EvidenceVideoThumbnail(path: '/validations/$validationId/evidence-file')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < photoCount; i++)
                  EvidencePhotoThumbnail(
                    path: '/validations/$validationId/evidence-file?index=$i',
                    allPaths: [
                      for (var j = 0; j < photoCount; j++)
                        '/validations/$validationId/evidence-file?index=$j',
                    ],
                    index: i,
                  ),
              ],
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
