import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

const _typeLabels = {
  'ally_invite_accepted': 'Invitation acceptée',
  'ally_request_received': "Demande d'alliance reçue",
  'ally_request_accepted': "Demande d'alliance acceptée",
  'validation_requested': 'Validation demandée',
  'validation_decided': 'Validation décidée',
  'quest_completed': 'Quête réussie',
  'quest_failed': 'Quête échouée',
  'quest_deadline_reminder': 'Échéance à venir',
  'payment_succeeded': 'Paiement réussi',
  'payment_failed': 'Paiement échoué',
  'quest_ally_invite_received': 'Invitation en tant qu\'allié',
  'quest_ally_invite_accepted': 'Invitation acceptée',
  'quest_deletion_requested': 'Suppression de quête demandée',
  'quest_deletion_approved': 'Suppression approuvée',
  'quest_deletion_rejected': 'Suppression rejetée',
};

class NotificationsView extends GetView<NotificationController> {
  const NotificationsView({super.key});

  void _open(AppNotification notification) {
    controller.markRead(notification.id);
    switch (notification.type) {
      case 'validation_requested':
        final evidenceId = notification.payload['evidenceId'];
        if (evidenceId is String) {
          Get.toNamed(AppRoutes.validationDetail, arguments: evidenceId);
        } else {
          Get.toNamed(AppRoutes.allyValidations);
        }
        break;
      case 'validation_decided':
        Get.toNamed(AppRoutes.allyValidations);
        break;
      case 'quest_completed':
      case 'quest_failed':
      case 'quest_deadline_reminder':
        final questId = notification.payload['questId'];
        if (questId is String) {
          Get.toNamed(AppRoutes.questDetail, arguments: questId);
        }
        break;
      case 'ally_request_received':
      case 'ally_request_accepted':
      case 'ally_invite_accepted':
        Get.toNamed(AppRoutes.inviteFriends);
        break;
      case 'quest_ally_invite_received':
        final questId = notification.payload['questId'];
        if (questId is String) {
          Get.toNamed(AppRoutes.questAllyInvitation, arguments: questId);
        }
        break;
      case 'quest_ally_invite_accepted':
      case 'quest_deletion_approved':
      case 'quest_deletion_rejected':
        final questId = notification.payload['questId'];
        if (questId is String) {
          Get.toNamed(AppRoutes.questDetail, arguments: questId);
        }
        break;
      case 'quest_deletion_requested':
        final questId = notification.payload['questId'];
        final requestId = notification.payload['requestId'];
        if (questId is String && requestId is String) {
          Get.toNamed(
            AppRoutes.questDeletionVote,
            arguments: {'questId': questId, 'requestId': requestId},
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                TextButton(
                  onPressed: controller.markAllRead,
                  child: Text(
                    'TOUT LIRE',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.notifications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.emerald),
                );
              }
              if (controller.notifications.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune notification.',
                    style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: controller.notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = controller.notifications[index];
                  return _NotificationRow(
                    notification: notification,
                    onTap: () => _open(notification),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  /// Builds a short second line so identical-type notifications (e.g. two
  /// "Invitation acceptée" rows) can be told apart — quest title, the other
  /// person's name, a validation decision, or a payment amount, depending
  /// on what that notification type's payload actually carries.
  String? get _detail {
    final payload = notification.payload;
    final questTitle = payload['questTitle'] as String? ?? payload['title'] as String?;
    if (questTitle != null && questTitle.isNotEmpty) return questTitle;

    final firstName = payload['firstName'] as String?;
    final lastName = payload['lastName'] as String?;
    if (firstName != null && firstName.isNotEmpty) {
      return [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    }

    if (notification.type == 'validation_decided') {
      final decision = payload['decision'] as String?;
      if (decision == 'approved') return 'Preuve approuvée';
      if (decision == 'rejected') return 'Preuve rejetée';
    }

    final amountXof = payload['amountXof'];
    if (amountXof is num) return formatXof(amountXof.toDouble());

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant15),
        ),
        child: Row(
          children: [
            if (notification.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 12),
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabels[notification.type] ?? notification.type,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: notification.isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (detail != null && detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
