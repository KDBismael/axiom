import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/controllers/quest_deletion_vote_controller.dart';
import 'package:axiom/features/quests/models/quest_deletion_request.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

void main() {
  late MockQuestRepository mockRepository;
  late QuestDeletionVoteController controller;

  const pendingRequest = QuestDeletionRequest(
    id: 'req-1',
    status: QuestDeletionRequestStatus.pending,
    votes: QuestDeletionVoteTally(approved: 1, total: 2),
  );

  setUp(() {
    mockRepository = MockQuestRepository();
    controller = QuestDeletionVoteController(mockRepository, 'q-1', 'req-1');
  });

  group('QuestDeletionVoteController.load', () {
    test('fetches and stores the request tally', () async {
      when(() => mockRepository.fetchDeletionRequest('q-1'))
          .thenAnswer((_) async => pendingRequest);

      await controller.load();

      expect(controller.request.value, pendingRequest);
    });

    test('surfaces the backend error on failure', () async {
      when(() => mockRepository.fetchDeletionRequest('q-1'))
          .thenThrow(QuestException('Demande introuvable'));

      await controller.load();

      expect(controller.errorMessage.value, 'Demande introuvable');
    });
  });

  group('QuestDeletionVoteController.vote', () {
    test('casts an approve vote and returns true', () async {
      when(() => mockRepository.voteOnDeletionRequest('q-1', 'req-1', approve: true))
          .thenAnswer((_) async {});

      final ok = await controller.vote(approve: true);

      expect(ok, isTrue);
      verify(() => mockRepository.voteOnDeletionRequest('q-1', 'req-1', approve: true)).called(1);
    });

    test('casts a reject vote and returns true', () async {
      when(() => mockRepository.voteOnDeletionRequest('q-1', 'req-1', approve: false))
          .thenAnswer((_) async {});

      final ok = await controller.vote(approve: false);

      expect(ok, isTrue);
    });

    test('surfaces the duplicate-vote error and returns false', () async {
      when(() => mockRepository.voteOnDeletionRequest('q-1', 'req-1', approve: true))
          .thenThrow(QuestException('Vous avez déjà voté sur cette demande'));

      final ok = await controller.vote(approve: true);

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Vous avez déjà voté sur cette demande');
    });
  });
}
