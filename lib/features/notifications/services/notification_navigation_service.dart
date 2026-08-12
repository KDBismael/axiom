import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/pending_invite_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/notification_model.dart';

RedirectTarget notificationTarget(String type, Map<String, dynamic> payload) {
  switch (type) {
    case 'validation_requested':
      final evidenceId = payload['evidenceId'];
      return evidenceId is String
          ? (route: AppRoutes.validationDetail, arguments: evidenceId)
          : (route: AppRoutes.allyValidations, arguments: null);
    case 'validation_decided':
      final questId = payload['questId'];
      return questId is String
          ? (route: AppRoutes.questDetail, arguments: questId)
          : (route: AppRoutes.allyValidations, arguments: null);
    case 'quest_completed':
    case 'quest_failed':
    case 'quest_deadline_reminder':
    case 'payment_succeeded':
    case 'payment_failed':
    case 'payout_sent':
    case 'refund_sent':
    case 'quest_ally_invite_accepted':
    case 'quest_deletion_approved':
    case 'quest_deletion_rejected':
      final questId = payload['questId'];
      return questId is String
          ? (route: AppRoutes.questDetail, arguments: questId)
          : (route: AppRoutes.notifications, arguments: null);
    case 'ally_request_received':
    case 'ally_request_accepted':
    case 'ally_invite_accepted':
      return (route: AppRoutes.inviteFriends, arguments: null);
    case 'quest_ally_invite_received':
      final questId = payload['questId'];
      return questId is String
          ? (route: AppRoutes.questAllyInvitation, arguments: questId)
          : (route: AppRoutes.notifications, arguments: null);
    case 'quest_deletion_requested':
      final questId = payload['questId'];
      final requestId = payload['requestId'];
      return questId is String && requestId is String
          ? (
              route: AppRoutes.questDeletionVote,
              arguments: {'questId': questId, 'requestId': requestId},
            )
          : (route: AppRoutes.notifications, arguments: null);
    default:
      return (route: AppRoutes.notifications, arguments: null);
  }
}

class NotificationNavigationService extends GetxService {
  void open(AppNotification notification) {
    openType(notification.type, notification.payload);
  }

  void openType(String type, Map<String, dynamic> payload) {
    final target = notificationTarget(type, payload);
    final auth = Get.find<AuthController>();
    if (!auth.isAuthenticated) {
      Get.find<PendingInviteService>().stashRedirect(target);
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    Get.toNamed(target.route, arguments: target.arguments);
  }
}
