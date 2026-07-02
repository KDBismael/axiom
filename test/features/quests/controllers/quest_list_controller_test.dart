import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';

QuestModel _stakeQuest(String id, double? stake) => QuestModel(
      id: id,
      title: 'Quest $id',
      durationDays: 10,
      frequency: QuestFrequency.daily,
      progress: 1,
      total: 10,
      stakeAmount: stake,
    );

void main() {
  setUp(() {
    Get.put<QuestRepository>(QuestRepository());
  });

  tearDown(Get.reset);

  group('QuestListController', () {
    test('totalStakeAmount sums the mock repository quests (100 + 500 + 250)', () async {
      final controller = QuestListController();
      await controller.loadQuests();
      expect(controller.totalStakeAmount, 850);
    });

    test('riskLevel is ÉLEVÉ when total stakes >= 500', () async {
      final controller = QuestListController();
      controller.quests.assignAll([_stakeQuest('1', 500)]);
      expect(controller.totalStakeAmount, 500);
      expect(controller.riskLevel, 'ÉLEVÉ');
    });

    test('riskLevel is MODÉRÉ between 200 and 500', () async {
      final controller = QuestListController();
      controller.quests.assignAll([_stakeQuest('1', 300)]);
      expect(controller.riskLevel, 'MODÉRÉ');
    });

    test('riskLevel is FAIBLE under 200, including quests with no stake', () async {
      final controller = QuestListController();
      controller.quests.assignAll([_stakeQuest('1', null), _stakeQuest('2', 50)]);
      expect(controller.totalStakeAmount, 50);
      expect(controller.riskLevel, 'FAIBLE');
    });

    test('createQuest appends the quest and it becomes findable', () async {
      final controller = QuestListController();
      await controller.loadQuests();
      final before = controller.quests.length;
      final quest = _stakeQuest('new-1', 42);
      await controller.createQuest(quest);
      expect(controller.quests.length, before + 1);
      expect(controller.findById('new-1'), isNotNull);
      expect(controller.findById('new-1')!.stakeAmount, 42);
    });
  });
}
