import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/controllers/quest_ally_invitation_controller.dart';
import 'package:axiom/features/quests/models/quest_ally_invitation.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

void main() {
  late MockQuestRepository mockRepository;
  late QuestAllyInvitationController controller;

  final invitation = QuestAllyInvitation(
    status: QuestAllyStatus.pending,
    questId: 'q-1',
    title: 'Courir tous les jours',
    description: '30 minutes de course',
    frequency: QuestFrequency.daily,
    durationDays: 30,
    startDate: DateTime(2026, 1, 1),
    deadline: DateTime(2026, 1, 31),
    hasStake: true,
    stakeAmountXof: 5000,
    fundsDistribution: FundsDistribution.allies,
  );

  setUp(() {
    mockRepository = MockQuestRepository();
    controller = QuestAllyInvitationController(mockRepository, 'q-1');
  });

  group('QuestAllyInvitationController.load', () {
    test('fetches and stores the invitation', () async {
      when(() => mockRepository.fetchAllyInvitation('q-1'))
          .thenAnswer((_) async => invitation);

      await controller.load();

      expect(controller.invitation.value, invitation);
      expect(controller.errorMessage.value, isNull);
    });

    test('surfaces the backend French error on failure', () async {
      when(() => mockRepository.fetchAllyInvitation('q-1'))
          .thenThrow(QuestException('Invitation introuvable'));

      await controller.load();

      expect(controller.errorMessage.value, 'Invitation introuvable');
      expect(controller.invitation.value, isNull);
    });
  });

  group('QuestAllyInvitationController.respond', () {
    test('accepts and returns true', () async {
      when(() => mockRepository.respondToAllyInvitation('q-1', accept: true))
          .thenAnswer((_) async {});

      final ok = await controller.respond(accept: true);

      expect(ok, isTrue);
      verify(() => mockRepository.respondToAllyInvitation('q-1', accept: true)).called(1);
    });

    test('declines and returns true', () async {
      when(() => mockRepository.respondToAllyInvitation('q-1', accept: false))
          .thenAnswer((_) async {});

      final ok = await controller.respond(accept: false);

      expect(ok, isTrue);
      verify(() => mockRepository.respondToAllyInvitation('q-1', accept: false)).called(1);
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(() => mockRepository.respondToAllyInvitation('q-1', accept: true))
          .thenThrow(QuestException('Cette invitation a déjà été traitée'));

      final ok = await controller.respond(accept: true);

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Cette invitation a déjà été traitée');
    });
  });
}
