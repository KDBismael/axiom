import 'package:get/get.dart';
import '../controllers/quest_list_controller.dart';
import '../repositories/quest_repository.dart';

class QuestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuestRepository>(() => QuestRepository());
    Get.lazyPut<QuestListController>(() => QuestListController());
  }
}
