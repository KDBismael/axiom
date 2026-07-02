import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:axiom/features/quests/controllers/quest_create_controller.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';

void main() {
  setUp(() {
    Get.put<QuestRepository>(QuestRepository());
    Get.put<QuestListController>(QuestListController());
  });

  tearDown(Get.reset);

  group('QuestCreateController', () {
    test('nextStep is a no-op on step 1 while the title is empty', () {
      final controller = QuestCreateController();
      controller.nextStep();
      expect(controller.currentStep.value, 0);
    });

    test('nextStep advances once a title is set', () {
      final controller = QuestCreateController();
      controller.titleController.text = 'Courir 5km';
      controller.nextStep();
      expect(controller.currentStep.value, 1);
    });

    test('nextStep does not advance past the last step', () {
      final controller = QuestCreateController();
      controller.titleController.text = 'Courir 5km';
      for (var i = 0; i < 10; i++) {
        controller.nextStep();
      }
      expect(controller.currentStep.value, QuestCreateController.stepCount - 1);
    });

    test('previousStep decrements and floors at 0', () {
      final controller = QuestCreateController();
      controller.titleController.text = 'Courir 5km';
      controller.nextStep();
      controller.nextStep();
      controller.previousStep();
      expect(controller.currentStep.value, 1);
      controller.previousStep();
      controller.previousStep();
      expect(controller.currentStep.value, 0);
    });

    test('toggleAlly adds and removes candidate ids', () {
      final controller = QuestCreateController();
      controller.toggleAlly('c1');
      expect(controller.selectedAllyIds, contains('c1'));
      controller.toggleAlly('c1');
      expect(controller.selectedAllyIds, isNot(contains('c1')));
    });

    test('submit builds a QuestModel from the entered fields and appends it', () async {
      final controller = QuestCreateController();
      controller.titleController.text = 'Courir 5km';
      controller.durationController.text = '14';
      controller.stakeController.text = '75';
      controller.frequency.value = QuestFrequency.daily;
      controller.toggleAlly('c1');

      await controller.submit();

      final listController = Get.find<QuestListController>();
      final created = listController.quests.firstWhere(
        (q) => q.title == 'Courir 5km',
      );
      expect(created.durationDays, 14);
      expect(created.stakeAmount, 75);
      expect(created.hasStake, isTrue);
      expect(created.allies, hasLength(1));
      expect(created.allies.first.name, 'Marcus Thorne');
      expect(created.allies.first.approved, isFalse);
    });
  });
}
