import 'package:get/get.dart';
import '../../features/auth/views/auth_view.dart';
import '../../features/profile/views/profile_view.dart';
import '../../features/quests/bindings/quest_binding.dart';
import '../../features/quests/views/quest_detail_view.dart';
import '../../features/quests/views/quest_list_view.dart';
import '../../features/shell/bindings/shell_binding.dart';
import '../../features/shell/views/main_shell_view.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.auth;

  static final pages = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellView(),
      binding: ShellBinding(),
    ),
    GetPage(
      name: AppRoutes.quests,
      page: () => const QuestListView(),
      binding: QuestBinding(),
    ),
    GetPage(
      name: AppRoutes.questDetail,
      page: () => const QuestDetailView(),
      binding: QuestBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
    ),
  ];
}
