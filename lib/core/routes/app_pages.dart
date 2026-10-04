import 'package:get/get.dart';
import '../../features/auth/views/auth_view.dart';
import '../../features/notifications/views/notifications_view.dart';
import '../../features/onboarding/controllers/onboarding_controller.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/quests/controllers/quest_ally_invitation_controller.dart';
import '../../features/quests/controllers/quest_owner_invitation_controller.dart';
import '../../features/quests/controllers/quest_group_invitation_controller.dart';
import '../../features/quests/controllers/quest_pause_decision_controller.dart';
import '../../features/quests/controllers/quest_create_controller.dart';
import '../../features/quests/controllers/quest_deletion_vote_controller.dart';
import '../../features/quests/controllers/quest_list_controller.dart';
import '../../features/quests/controllers/focus_timer_controller.dart';
import '../../features/quests/repositories/quest_repository.dart';
import '../../features/quests/services/focus_session_draft_store.dart';
import '../../features/quests/views/quest_focus_timer_view.dart';
import '../../features/quests/views/quest_ally_invitation_view.dart';
import '../../features/quests/views/quest_owner_invitation_view.dart';
import '../../features/quests/views/quest_group_invitation_view.dart';
import '../../features/quests/views/quest_pause_decision_view.dart';
import '../../features/quests/views/quest_create_view.dart';
import '../../features/quests/views/quest_deletion_vote_view.dart';
import '../../features/quests/views/quest_detail_view.dart';
import '../../features/payments/bindings/quest_payment_binding.dart';
import '../../features/payments/views/quest_payment_view.dart';
import '../../features/profile/views/manage_allies_sheet_route.dart';
import '../../features/social/views/ally_validations_view.dart';
import '../../features/social/views/ally_request_view.dart';
import '../../features/social/views/invitation_ally_view.dart';
import '../../features/social/controllers/allies_controller.dart';
import '../../features/social/repositories/social_repository.dart';
import '../../features/social/views/validation_detail_view.dart';
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
      binding: BindingsBuilder(() {
        Get.lazyPut<OnboardingController>(() => OnboardingController());
      }),
    ),
    GetPage(name: AppRoutes.login, page: () => const AuthView()),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellView(),
      binding: ShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(name: AppRoutes.questDetail, page: () => const QuestDetailView()),
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
      page: () => const ManageAlliesSheetRoute(),
    ),
    GetPage(
      name: AppRoutes.allyRequest,
      page: () => const AllyRequestView(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<SocialRepository>()) {
          Get.lazyPut<SocialRepository>(() => SocialRepository(Get.find()));
        }
        if (!Get.isRegistered<AlliesController>()) {
          Get.lazyPut<AlliesController>(() => AlliesController(Get.find()));
        }
      }),
    ),
    GetPage(
      name: AppRoutes.questCreate,
      page: () => const QuestCreateView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<QuestCreateController>(
          () => QuestCreateController(Get.find<QuestListController>()),
        );
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
      name: AppRoutes.questOwnerInvitation,
      page: () => const QuestOwnerInvitationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<QuestOwnerInvitationController>(
          () => QuestOwnerInvitationController(
            Get.find<QuestRepository>(),
            Get.arguments as String,
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.questGroupInvitation,
      page: () => const QuestGroupInvitationView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<QuestGroupInvitationController>(
          () => QuestGroupInvitationController(
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
      name: AppRoutes.questPauseDecision,
      page: () => const QuestPauseDecisionView(),
      binding: BindingsBuilder(() {
        final args = Get.arguments as Map<String, String>;
        Get.lazyPut<QuestPauseDecisionController>(
          () => QuestPauseDecisionController(
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
      binding: QuestPaymentBinding(),
    ),
    GetPage(
      name: AppRoutes.questFocusTimer,
      page: () => const QuestFocusTimerView(),
      binding: BindingsBuilder(() {
        // Tagged + permanent: leaving this route must not stop the running
        // timer (or the live/foreground presence it drives) — a plain
        // lazyPut controller is disposed by GetX as soon as the route is
        // popped. It's freed explicitly once the session is actually
        // submitted (quest_validation_view.dart) or replaced by a fresh one
        // the next time this route opens for the same quest.
        final questId = Get.arguments as String;
        if (!Get.isRegistered<FocusTimerController>(tag: questId)) {
          Get.put<FocusTimerController>(
            FocusTimerController(
              Get.find<QuestListController>(),
              Get.find<FocusSessionDraftStore>(),
              questId,
            ),
            tag: questId,
            permanent: true,
          );
        }
      }),
    ),
  ];
}
