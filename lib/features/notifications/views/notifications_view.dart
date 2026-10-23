import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../services/notification_navigation_service.dart';

const _typeLabels = {
  'ally_invite_accepted': 'Invitation acceptée',
  'ally_request_received': "Demande d'alliance reçue",
  'ally_request_accepted': "Demande d'alliance acceptée",
  'ally_request_declined': "Demande d'alliance refusée",
  'ally_removed': 'Alliance terminée',
  'validation_requested': 'Validation demandée',
  'validation_decided': 'Validation décidée',
  'quest_completed': 'Quête réussie',
  'quest_failed': 'Quête échouée',
  'quest_deadline_reminder': 'Échéance à venir',
  'payment_succeeded': 'Paiement réussi',
  'payment_failed': 'Paiement échoué',
  'payout_sent': 'Versement envoyé',
  'refund_sent': 'Remboursement envoyé',
  'payout_rejected': 'Versement refusé',
  'refund_rejected': 'Remboursement refusé',
  'quest_ally_invite_received': 'Invitation en tant qu\'allié',
  'quest_ally_invite_accepted': 'Invitation acceptée',
  'quest_owner_invite_received': 'Invitation à reprendre une quête',
  'quest_owner_invite_accepted': 'Reprise de quête acceptée',
  'quest_owner_invite_declined': 'Reprise de quête refusée',
  'quest_owner_invite_expired': 'Invitation à reprendre une quête expirée',
  'quest_deletion_requested': 'Suppression de quête demandée',
  'quest_deletion_approved': 'Suppression approuvée',
  'quest_deletion_rejected': 'Suppression rejetée',
  'quest_group_invite_received': 'Invitation à une quête collective',
  'quest_group_member_joined': 'Un membre a rejoint la quête',
  'quest_group_invite_declined': 'Invitation refusée',
  'quest_pause_requested': 'Demande de pause à valider',
  'quest_pause_decided': 'Verdict sur votre pause',
};

/// Category accent color per notification family — matches the "Ndeli —
/// Arène" palette's semantic colors (social=violet, success=volt,
/// failure=error, time-sensitive=amber, money=wave cyan).
Color _accentFor(String type) {
  if (type.startsWith('ally_')) return AppColors.violet;
  if (type.startsWith('quest_ally_invite') ||
      type.startsWith('quest_group_invite') ||
      type.startsWith('quest_owner_invite')) {
    return AppColors.violet;
  }
  if (type == 'quest_completed' || type == 'validation_decided') return AppColors.volt;
  if (type == 'quest_failed' || type.contains('rejected') || type == 'payment_failed') {
    return AppColors.error;
  }
  if (type == 'quest_deadline_reminder' || type.contains('pause')) return AppColors.amber;
  if (type.startsWith('payment_') || type.contains('payout') || type.contains('refund')) {
    return AppColors.waveCyan;
  }
  return AppColors.outlineMuted;
}

String _relativeTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  if (diff == 1) return 'Hier';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}

class NotificationsView extends GetView<NotificationController> {
  const NotificationsView({super.key});

  void _open(AppNotification notification) {
    controller.markRead(notification.id);
    Get.find<NotificationNavigationService>().open(notification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontSize: 18),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.markAllRead,
                    child: Text(
                      'Tout lire',
                      style: const TextStyle(fontFamily: 'Geist', color: AppColors.volt, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.notifications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.volt),
                );
              }
              if (controller.notifications.isEmpty) {
                return Center(
                  child: Text(
                    'Aucune notification.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
    final questTitle =
        payload['questTitle'] as String? ?? payload['title'] as String?;
    final firstName = payload['firstName'] as String?;
    final lastName = payload['lastName'] as String?;
    if (questTitle != null && questTitle.isNotEmpty) return questTitle;
    if (firstName != null && firstName.isNotEmpty) {
      return [
        firstName,
        lastName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');
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
    final accent = _accentFor(notification.type);
    final isUnread = notification.isUnread;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.structuralRadius,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? Color.alphaBlend(
                  AppColors.voltTint(),
                  AppColors.surfaceContainerLow,
                )
              : AppColors.surfaceContainerLowest,
          borderRadius: AppRadii.structuralRadius,
          border: Border.all(
            color: isUnread
                ? AppColors.volt.withValues(alpha: 0.55)
                : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Transform.rotate(
                angle: 0.7853981633974483,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (_typeLabels[notification.type] ?? 'Notification')
                              .toUpperCase(),
                          style: AppTypography.labelMd.copyWith(
                            color: accent,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        isUnread ? Icons.circle : Icons.done,
                        size: 12,
                        color: isUnread ? AppColors.volt : AppColors.outline,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isUnread ? 'Non lue' : 'Lue',
                        style: AppTypography.bodyMd.copyWith(
                          color: isUnread ? AppColors.volt : AppColors.outline,
                          fontSize: 12,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  if (detail != null && detail.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
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
