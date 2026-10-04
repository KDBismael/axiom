import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/avatar_colors.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally.dart';

/// "Gérer mes alliés" — the existing-allies list, with the only action
/// being to remove one. Recruiting a *new* ally (search, invite link,
/// share, redeeming a received code) lives entirely in `InviteFriendsSheet`
/// instead, reached from Profile's own "Inviter des amis" row — the two
/// flows are intentionally separate.
class ManageAlliesSheet extends StatefulWidget {
  const ManageAlliesSheet({super.key});

  @override
  State<ManageAlliesSheet> createState() => _ManageAlliesSheetState();
}

class _ManageAlliesSheetState extends State<ManageAlliesSheet> {
  late final AlliesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AlliesController>();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeAlly(Ally ally) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer cet allié ?'),
        content: Text(
          '${ally.firstName} ${ally.lastName} ne fera plus partie de vos alliés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('RETIRER'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = await _controller.removeAlly(ally.id);
    if (!mounted) return;
    if (!removed) {
      _showSnack(
        _controller.errorMessage.value ?? 'Impossible de retirer cet allié.',
      );
      return;
    }
    _showSnack('${ally.firstName} a été retiré de vos alliés.');
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RÉSEAU',
              style: AppTypography.labelMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gérer mes alliés',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final allies = _controller.allies;
              if (allies.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aucun allié pour le moment.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                );
              }
              return Column(
                children: [
                  for (final ally in allies) ...[
                    _AllyRow(ally: ally, onRemove: () => _removeAlly(ally)),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Fermer',
                  style: TextStyle(fontSize: 14, color: AppColors.outline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllyRow extends StatelessWidget {
  const _AllyRow({required this.ally, required this.onRemove});

  final Ally ally;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2210),
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: const Color(0xFF2F3F14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColorForId(ally.id),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initialsFor(ally.firstName, ally.lastName),
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${ally.firstName} ${ally.lastName}',
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariantStrong),
              ),
              child: const Text(
                'Retirer',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
