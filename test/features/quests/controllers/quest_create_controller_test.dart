import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/controllers/quest_create_controller.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/payments/services/payment_feature_config.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockQuestRepository mockRepository;
  late QuestListController listController;
  late QuestCreateController controller;

  QuestModel quest() => QuestModel(
    id: 'q-1',
    title: 'Gym',
    description: '',
    creatorId: 'user-1',
    frequency: QuestFrequency.daily,
    durationDays: 30,
    targetPerPeriod: 1,
    startDate: DateTime(2026, 1, 1),
    deadline: DateTime(2026, 1, 31),
    gracePeriodDays: 0,
    riskLevel: QuestRiskLevel.medium,
    requiresProof: false,
    successThresholdPercent: 80,
    hasStake: false,
    status: QuestStatus.active,
    progress: 0,
    streakDays: 0,
  );

  setUp(() {
    mockRepository = MockQuestRepository();
    listController = QuestListController(mockRepository);
    controller = QuestCreateController(listController);
  });

  group('QuestCreateController.nextStep', () {
    test('is a no-op on step 0 while the title is empty', () {
      controller.nextStep();
      expect(controller.currentStep.value, 0);
    });

    test('advances once a title is entered', () {
      controller.titleController.text = 'Courir 5km';
      controller.nextStep();
      expect(controller.currentStep.value, 1);
    });

    test('does not advance past the last step', () {
      controller.titleController.text = 'Courir 5km';
      for (var i = 0; i < 10; i++) {
        controller.nextStep();
      }
      expect(controller.currentStep.value, controller.stepCount - 1);
    });
  });

  group('QuestCreateController.previousStep', () {
    test('decrements and floors at 0', () {
      controller.titleController.text = 'Courir 5km';
      controller.nextStep();
      controller.nextStep();
      controller.previousStep();
      expect(controller.currentStep.value, 1);
      controller.previousStep();
      controller.previousStep();
      expect(controller.currentStep.value, 0);
    });
  });

  group('QuestCreateController.submit', () {
    test(
      'creates the quest directly (pending_payment), not a draft intent, when stake is enabled',
      () async {
        when(() => mockRepository.createQuest(any())).thenAnswer(
          (_) async => QuestModel(
            id: 'q-2',
            title: 'Courir 5km',
            description: '',
            creatorId: 'user-1',
            frequency: QuestFrequency.daily,
            durationDays: 30,
            targetPerPeriod: 1,
            startDate: DateTime(2026, 1, 1),
            deadline: DateTime(2026, 1, 31),
            gracePeriodDays: 0,
            riskLevel: QuestRiskLevel.medium,
            requiresProof: false,
            successThresholdPercent: 80,
            hasStake: true,
            status: QuestStatus.pendingPayment,
            progress: 0,
            streakDays: 0,
          ),
        );
        final stakeController = QuestCreateController(
          listController,
          paymentConfig: const PaymentFeatureConfig(
            payInsEnabled: true,
            environment: 'sandbox',
            sandboxVerified: true,
          ),
        );
        stakeController.titleController.text = 'Courir 5km';
        stakeController.hasStake.value = true;
        stakeController.stakeController.text = '5000';

        final ok = await stakeController.submit();

        expect(ok, isTrue);
        final captured =
            verify(
                  () => mockRepository.createQuest(captureAny()),
                ).captured.single
                as Map;
        expect(captured['hasStake'], isTrue);
        expect(captured['stakeAmountXof'], 5000.0);
        expect(stakeController.createdQuest.value?.isPendingPayment, isTrue);
        stakeController.onClose();
      },
    );

    test('sends the full payload for a no-stake quest', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());

      controller.titleController.text = 'Courir 5km';
      controller.descriptionController.text = 'Chaque matin.';
      controller.durationController.text = '30';
      controller.gracePeriodController.text = '2';
      controller.successThresholdPercent.value = 80;

      final ok = await controller.submit();

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured['title'], 'Courir 5km');
      expect(captured['description'], 'Chaque matin.');
      expect(captured['durationDays'], 30);
      expect(captured['targetPerPeriod'], 1);
      expect(captured['gracePeriodDays'], 2);
      expect(captured['successThresholdPercent'], 80);
      expect(captured['hasStake'], isFalse);
      expect(captured.containsKey('stakeAmountXof'), isFalse);
      expect(ok, isTrue);
    });

    test('sends the entered targetPerPeriod', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());

      controller.titleController.text = 'Manger équilibré';
      controller.targetPerPeriodController.text = '3';

      await controller.submit();

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured['targetPerPeriod'], 3);
    });

    test(
      'forces payment fields off while the feature is unavailable',
      () async {
        when(
          () => mockRepository.createQuest(any()),
        ).thenAnswer((_) async => quest());

        controller.titleController.text = 'Courir 5km';
        controller.hasStake.value = true;
        controller.stakeController.text = '5000';

        await controller.submit();

        final captured =
            verify(
                  () => mockRepository.createQuest(captureAny()),
                ).captured.single
                as Map;
        expect(captured['hasStake'], isFalse);
        expect(captured.containsKey('stakeAmountXof'), isFalse);
        expect(captured.containsKey('fundsDistribution'), isFalse);
      },
    );

    test(
      'surfaces the backend French error and returns false on failure',
      () async {
        when(
          () => mockRepository.createQuest(any()),
        ).thenThrow(QuestException('Titre invalide'));

        controller.titleController.text = 'Courir 5km';
        final ok = await controller.submit();

        expect(ok, isFalse);
        expect(controller.errorMessage.value, 'Titre invalide');
      },
    );

    test('omits allyUserIds when no ally is selected', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());

      controller.titleController.text = 'Courir 5km';
      await controller.submit();

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured.containsKey('allyUserIds'), isFalse);
    });

    test('includes allyUserIds for each selected ally', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());

      controller.titleController.text = 'Courir 5km';
      controller.toggleAlly('ally-1');
      controller.toggleAlly('ally-2');
      await controller.submit();

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured['allyUserIds'], containsAll(['ally-1', 'ally-2']));
    });

    test('omits inviteeId when not creating for someone else', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());

      controller.titleController.text = 'Courir 5km';
      controller.selectedInviteeId.value = 'user-2';
      await controller.submit();

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured.containsKey('inviteeId'), isFalse);
    });

    test('includes inviteeId when sponsoring someone else', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());

      controller.titleController.text = 'Courir 5km';
      controller.createForSomeoneElse.value = true;
      controller.selectedInviteeId.value = 'user-2';
      await controller.submit();

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured['inviteeId'], 'user-2');
    });
  });

  group('QuestCreateController.createForSomeoneElse', () {
    test('stepCount is 5 by default and 6 while sponsoring', () {
      expect(controller.stepCount, 5);
      controller.createForSomeoneElse.value = true;
      expect(controller.stepCount, 6);
    });

    test('selectInvitee toggles selection on repeated taps', () {
      controller.selectInvitee('user-2');
      expect(controller.selectedInviteeId.value, 'user-2');
      controller.selectInvitee('user-2');
      expect(controller.selectedInviteeId.value, isNull);
    });

    test('canProceedFromInvitee requires a selected invitee', () {
      expect(controller.canProceedFromInvitee, isFalse);
      controller.selectedInviteeId.value = 'user-2';
      expect(controller.canProceedFromInvitee, isTrue);
    });
  });

  group('QuestCreateController.isCollective', () {
    test('stepCount drops the stake step (4 steps, no invitee/stake)', () {
      controller.isCollective.value = true;
      expect(controller.stepCount, 4);
    });

    test('submit posts to createQuestGroup, with no stake fields and memberUserIds instead of allyUserIds', () async {
      when(
        () => mockRepository.createQuestGroup(any()),
      ).thenAnswer((_) async => quest());

      controller.isCollective.value = true;
      controller.titleController.text = 'Défi 30 jours';
      controller.descriptionController.text = 'On se motive ensemble';
      controller.toggleAlly('user-2');
      controller.toggleAlly('user-3');
      controller.hasStake.value = true; // must be ignored for a collective quest
      controller.stakeController.text = '5000';

      final ok = await controller.submit();

      verifyNever(() => mockRepository.createQuest(any()));
      final captured =
          verify(
                () => mockRepository.createQuestGroup(captureAny()),
              ).captured.single
              as Map;
      expect(captured['title'], 'Défi 30 jours');
      expect(captured['description'], 'On se motive ensemble');
      expect(captured['memberUserIds'], containsAll(['user-2', 'user-3']));
      expect(captured.containsKey('allyUserIds'), isFalse);
      expect(captured.containsKey('hasStake'), isFalse);
      expect(captured.containsKey('stakeAmountXof'), isFalse);
      expect(captured.containsKey('inviteeId'), isFalse);
      expect(ok, isTrue);
    });

    test('submit omits memberUserIds when no one is selected', () async {
      when(
        () => mockRepository.createQuestGroup(any()),
      ).thenAnswer((_) async => quest());

      controller.isCollective.value = true;
      controller.titleController.text = 'Défi solo pour le moment';
      await controller.submit();

      final captured =
          verify(
                () => mockRepository.createQuestGroup(captureAny()),
              ).captured.single
              as Map;
      expect(captured.containsKey('memberUserIds'), isFalse);
    });

    test(
      'surfaces the backend French error and returns false on failure',
      () async {
        when(
          () => mockRepository.createQuestGroup(any()),
        ).thenThrow(QuestException('Titre invalide'));

        controller.isCollective.value = true;
        controller.titleController.text = 'Défi 30 jours';
        final ok = await controller.submit();

        expect(ok, isFalse);
        expect(controller.errorMessage.value, 'Titre invalide');
      },
    );
  });

  group('QuestCreateController tolerated absences', () {
    test('derives the default daily allowance from the 80 percent rule', () {
      expect(controller.expectedPeriods, 30);
      expect(controller.requiredPeriods, 24);
      expect(controller.missedPeriodsAllowed, 6);
    });

    test('uses weeks for a weekly quest', () {
      controller.frequency.value = QuestFrequency.weekly;

      expect(controller.expectedPeriods, 5);
      expect(controller.requiredPeriods, 4);
      expect(controller.missedPeriodsAllowed, 1);
    });

    test('converts the selected missed periods back to an API threshold', () {
      controller.setMissedPeriodsAllowed(3);

      expect(controller.successThresholdPercent.value, 90);
      expect(controller.requiredPeriods, 27);
      expect(controller.missedPeriodsAllowed, 3);
    });

    test('clamps a negative catch-up delay to zero in the payload', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest());
      controller.titleController.text = 'Courir';
      controller.gracePeriodController.text = '-4';

      await controller.submit();

      final payload =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(payload['gracePeriodDays'], 0);
    });
  });

  group('QuestCreateController.toggleAlly', () {
    test('adds then removes a selected ally id', () {
      controller.toggleAlly('ally-1');
      expect(controller.selectedAllyIds, {'ally-1'});
      controller.toggleAlly('ally-1');
      expect(controller.selectedAllyIds, isEmpty);
    });
  });
}
