import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/avatar_colors.dart';
import '../controllers/validations_controller.dart';
import '../models/ally_validation_request.dart';
import '../widgets/validation_card.dart';

/// Merged "Validations" screen — pending proofs to judge and the history of
/// ones already decided, switched via a segmented tab (matches the mockup's
/// INBOX `inboxTabs`; same merge treatment as the auth screen).
/// `Get.arguments == 'done'` opens straight on the second tab (used by
/// Profile's "history" entry point); anything else opens on pending.
class AllyValidationsView extends StatefulWidget {
  const AllyValidationsView({super.key});

  @override
  State<AllyValidationsView> createState() => _AllyValidationsViewState();
}

class _AllyValidationsViewState extends State<AllyValidationsView> {
  late bool _pendingTab = Get.arguments != 'done';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ValidationsController>();
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'Validations',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadii.interactiveRadius,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  _Tab(
                    label: 'En attente',
                    selected: _pendingTab,
                    onTap: () => setState(() => _pendingTab = true),
                  ),
                  _Tab(
                    label: 'Traitées',
                    selected: !_pendingTab,
                    onTap: () => setState(() => _pendingTab = false),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_pendingTab) {
                final pending = controller.pendingValidations;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: pending.isEmpty
                      ? const _EmptyState(
                          title: 'Tout est jugé',
                          subtitle: "Aucune preuve n'attend ton verdict.",
                          icon: Icons.verified_user_outlined,
                        )
                      : Column(
                          children: [
                            for (final request in pending) ...[
                              ValidationCard(
                                request: request,
                                onApprove: (comment) => controller.decide(
                                  request.id,
                                  approved: true,
                                  comment: comment,
                                ),
                                onReject: (comment) => controller.decide(
                                  request.id,
                                  approved: false,
                                  comment: comment,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                );
              }
              final decided = controller.decidedValidations;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                child: decided.isEmpty
                    ? const _EmptyState(
                        title: 'Aucune validation traitée',
                        subtitle:
                            'Les décisions de tes alliés apparaîtront ici.',
                        icon: Icons.history,
                      )
                    : Column(
                        children: [
                          for (final request in decided) ...[
                            _DecidedRow(request: request),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: selected ? AppColors.onPrimary : AppColors.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Transform.rotate(
            angle: 0.7853981633974483,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outlineMuted),
          ),
        ],
      ),
    );
  }
}

/// Compact row for a decided validation — matches the mockup's "Traitées"
/// list rows (initials chip + who/quest/date + outcome pill) rather than
/// reusing the full [DecidedValidationCard] (built for the single-item
/// deep-link screen, where the full proof is worth re-showing).
class _DecidedRow extends StatelessWidget {
  const _DecidedRow({required this.request});

  final AllyValidationRequest request;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (request.status) {
      ValidationDecisionStatus.approved => ('APPROUVÉE', AppColors.volt),
      ValidationDecisionStatus.rejected => ('REJETÉE', AppColors.error),
      ValidationDecisionStatus.cancelled => ('ANNULÉE', AppColors.outlineMuted),
      ValidationDecisionStatus.pending => ('', AppColors.outline),
    };
    final initials = initialsForDisplayName(request.submitterName);
    final avatarColor = avatarColorForId(
      request.submitterId ?? request.submitterName,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 11,
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
                  request.submitterName.isEmpty
                      ? 'Allié'
                      : request.submitterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.questTitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.outlineMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 10.5,
                letterSpacing: 0.1 * 10.5,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
