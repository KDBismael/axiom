import 'package:get/get.dart';
import '../../features/auth/views/login_view.dart';
import '../../features/auth/views/register_view.dart';
import '../../features/onboarding/views/onboarding_view.dart';
import '../../features/quests/controllers/quest_create_controller.dart';
import '../../features/quests/views/quest_create_view.dart';
import '../../features/quests/views/quest_detail_view.dart';
import '../../features/quests/views/quest_payment_view.dart';
import '../../features/profile/views/invite_friends_view.dart';
import '../../features/social/views/ally_validations_view.dart';
import '../../features/social/views/invitation_ally_view.dart';
import '../../features/quests/views/quest_checkin_status_view.dart';
import '../../features/quests/views/quest_validation_view.dart';
import '../../features/shell/bindings/shell_binding.dart';
import '../../features/shell/views/main_shell_view.dart';
import 'app_routes.dart';

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
        Get.lazyPut<QuestCreateController>(() => QuestCreateController());
      }),
    ),
    GetPage(
      name: AppRoutes.questPayment,
      page: () => const QuestPaymentView(),
    ),
    GetPage(
      name: AppRoutes.invitationAlly,
      page: () => const InvitationAllyView(),
    ),
    GetPage(
      name: AppRoutes.allyValidations,
      page: () => const AllyValidationsView(),
    ),
  ];
}
