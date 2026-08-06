import 'package:get/get.dart';
import '../../quests/controllers/quest_list_controller.dart';

class ShellController extends GetxController {
  final currentIndex = 0.obs;

  /// The dashboard and history tabs live in a shared [IndexedStack] that's
  /// built once, so switching to them never re-fetches — without this, an
  /// update from elsewhere in the app (a check-in, a decision) stays
  /// invisible until the app is fully restarted.
  void changeTab(int index) {
    currentIndex.value = index;
    if (!Get.isRegistered<QuestListController>()) return;
    final quests = Get.find<QuestListController>();
    if (index == 0) {
      quests.loadQuests();
      quests.loadPendingAllyInvitations();
    } else if (index == 1) {
      quests.loadQuests();
    }
  }
}
