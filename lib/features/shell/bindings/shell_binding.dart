import 'package:get/get.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/repositories/quest_repository.dart';
import '../../social/controllers/social_controller.dart';
import '../../social/repositories/social_repository.dart';
import '../controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    Get.lazyPut<QuestRepository>(() => QuestRepository());
    Get.lazyPut<QuestListController>(() => QuestListController());
    Get.lazyPut<SocialRepository>(() => SocialRepository());
    Get.lazyPut<SocialController>(() => SocialController());
  }
}
