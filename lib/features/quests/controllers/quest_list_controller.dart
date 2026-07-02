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

  Future<void> createQuest(QuestModel quest) async {
    final created = await _repository.createQuest(quest);
    quests.add(created);
  }

  QuestModel? findById(String id) {
    try {
      return quests.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalStakeAmount =>
      quests.fold(0, (sum, quest) => sum + (quest.stakeAmount ?? 0));

  String get riskLevel {
    if (totalStakeAmount >= 500) return 'ÉLEVÉ';
    if (totalStakeAmount >= 200) return 'MODÉRÉ';
    return 'FAIBLE';
  }
}
