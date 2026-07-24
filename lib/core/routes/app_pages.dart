import 'package:get/get.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/notifications/views/notifications_view.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/quests/controllers/quest_ally_invitation_controller.dart';
import '../../features/quests/controllers/quest_create_controller.dart';
import '../../features/quests/controllers/quest_deletion_vote_controller.dart';
import '../../features/quests/controllers/quest_list_controller.dart';
import '../../features/quests/repositories/quest_repository.dart';
import '../../features/quests/views/quest_ally_invitation_view.dart';
import '../../features/quests/views/quest_create_view.dart';
import '../../features/quests/views/quest_deletion_vote_view.dart';
import '../../features/quests/views/quest_detail_view.dart';
import '../../features/payments/controllers/quest_payment_controller.dart';
import '../../features/payments/repositories/payment_repository.dart';
import '../../features/payments/services/url_opener.dart';
import '../../features/payments/views/quest_payment_view.dart';
import '../../features/profile/views/invite_friends_view.dart';
import '../../features/social/views/ally_validations_view.dart';
import '../../features/social/views/invitation_ally_view.dart';
import '../../features/social/views/validation_detail_view.dart';
import '../../features/social/views/validation_history_view.dart';
import '../../features/quests/views/quest_checkin_status_view.dart';
import '../../features/quests/views/quest_validation_view.dart';
import '../../features/shell/bindings/shell_binding.dart';
import '../../features/shell/views/main_shell_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellView(),
      binding: ShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.questDetail,
      page: () => const QuestDetailView(),
    ),
    GetPage(
      name: AppRoutes.questValidation,
      page: () => const QuestValidationView(),
    ),
    GetPage(
      name: AppRoutes.questCheckinStatus,
      page: () => const QuestCheckinStatusView(),
    ),
    GetPage(
      name: AppRoutes.inviteFriends,
      page: () => const InviteFriendsView(),
    ),
    GetPage(
      name: AppRoutes.questCreate,
      page: () => const QuestCreateView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<QuestCreateController>(() => QuestCreateController(Get.find<QuestListController>()));
      }),
    ),
    GetPage(
      name: AppRoutes.invitationAlly,
      page: () => const InvitationAllyView(),
    ),
    GetPage(
      name: AppRoutes.allyValidations,
      page: () => const AllyValidationsView(),
    ),
    GetPage(
      name: AppRoutes.validationDetail,
      page: () => const ValidationDetailView(),
    ),
    GetPage(
      name: AppRoutes.validationHistory,
      page: () => const ValidationHistoryView(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
    ),
    GetPage(
      name: AppRoutes.questAllyInvitation,
      page: () => const QuestAllyInvitationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<QuestAllyInvitationController>(
          () => QuestAllyInvitationController(
            Get.find<QuestRepository>(),
            Get.arguments as String,
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.questDeletionVote,
      page: () => const QuestDeletionVoteView(),
      binding: BindingsBuilder(() {
        final args = Get.arguments as Map<String, String>;
        Get.lazyPut<QuestDeletionVoteController>(
          () => QuestDeletionVoteController(
            Get.find<QuestRepository>(),
            args['questId']!,
            args['requestId']!,
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.questPayment,
      page: () => const QuestPaymentView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<QuestPaymentController>(
          () => QuestPaymentController(
            Get.find<PaymentRepository>(),
            Get.find<QuestListController>(),
            Get.find<UrlOpener>(),
            Get.arguments as String,
          ),
        );
      }),
    ),
  ];
}
