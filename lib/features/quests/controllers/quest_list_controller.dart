import 'package:get/get.dart';
import '../models/quest_model.dart';
import '../repositories/quest_repository.dart';

class QuestListController extends GetxController {
  final QuestRepository _repository = Get.find();

  final quests = <QuestModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadQuests();
  }

  Future<void> loadQuests() async {
    isLoading(true);
    try {
      final data = await _repository.fetchQuests();
      quests.assignAll(data);
    } finally {
      isLoading(false);
    }
  }

  Future<void> checkIn(String questId) async {
    final updated = await _repository.checkIn(questId);
    final index = quests.indexWhere((q) => q.id == questId);
    if (index != -1) {
      quests[index] = updated;
      // ignore: invalid_use_of_protected_member
      quests.refresh();
    }
  }

  QuestModel? findById(String id) {
    try {
      return quests.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}
