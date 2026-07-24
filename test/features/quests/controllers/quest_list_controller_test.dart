import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/models/quest_ally_invitation_summary.dart';
import 'package:axiom/features/quests/models/quest_deletion_request.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';

class MockQuestRepository extends Mock implements QuestRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ProofType.text);
  });

  late MockQuestRepository mockRepository;
  late QuestListController controller;

  QuestModel quest({
    String id = 'q-1',
    QuestStatus status = QuestStatus.active,
    double stakeAmountXof = 0,
    bool hasStake = false,
  }) {
    return QuestModel(
      id: id,
      title: 'Gym',
      description: '',
      frequency: QuestFrequency.daily,
      durationDays: 10,
      targetPerPeriod: 1,
      startDate: DateTime(2026, 1, 1),
      deadline: DateTime(2026, 1, 11),
      gracePeriodDays: 0,
      riskLevel: QuestRiskLevel.medium,
      requiresProof: false,
      successThresholdPercent: 80,
      hasStake: hasStake,
      stakeAmountXof: hasStake ? stakeAmountXof : null,
      status: status,
      progress: 0.1,
      streakDays: 1,
    );
  }

  setUp(() {
    mockRepository = MockQuestRepository();
    controller = QuestListController(mockRepository);
  });

  group('QuestListController.loadQuests', () {
    test('populates quests on success', () async {
      when(() => mockRepository.fetchQuests())
          .thenAnswer((_) async => [quest(id: 'q-1'), quest(id: 'q-2')]);

      await controller.loadQuests();

      expect(controller.quests, hasLength(2));
      expect(controller.isLoading.value, isFalse);
    });

    test('surfaces the backend French message on failure', () async {
      when(() => mockRepository.fetchQuests()).thenThrow(QuestException('Non authentifié'));

      await controller.loadQuests();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.quests, isEmpty);
    });
  });

  group('QuestListController.createQuest', () {
    test('sends the payload and appends the created quest', () async {
      when(() => mockRepository.createQuest(any())).thenAnswer((_) async => quest(id: 'new-1'));

      await controller.createQuest({'title': 'Gym'});

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single as Map;
      expect(captured['title'], 'Gym');
      expect(controller.findById('new-1'), isNotNull);
    });

    test('a quest created with hasStake renders as pending_payment', () async {
      when(() => mockRepository.createQuest(any())).thenAnswer(
        (_) async => quest(id: 'stake-1', status: QuestStatus.pendingPayment, hasStake: true),
      );

      await controller.createQuest({'title': 'Gym', 'hasStake': true});

      expect(controller.findById('stake-1')!.isPendingPayment, isTrue);
    });
  });

  group('QuestListController.checkIn', () {
    test('refreshes the quest in place on success', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.checkIn(
            'q-1',
            date: any(named: 'date'),
            proofType: any(named: 'proofType'),
            fileId: any(named: 'fileId'),
            textContent: any(named: 'textContent'),
            description: any(named: 'description'),
          )).thenAnswer(
        (_) async => CheckInResult(
          checkIn: CheckIn(id: 'ci-1', questId: 'q-1', date: DateTime(2026, 1, 2)),
          streakDays: 2,
          progress: 0.2,
          currentPeriodCount: 1,
          targetPerPeriod: 1,
        ),
      );
      when(() => mockRepository.fetchQuest('q-1')).thenAnswer(
        (_) async => quest(id: 'q-1').copyWith(progress: 0.2, streakDays: 2),
      );

      await controller.checkIn('q-1');

      expect(controller.findById('q-1')!.progress, 0.2);
      expect(controller.findById('q-1')!.streakDays, 2);
    });

    test('surfaces the dedup 409 French message without throwing', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.checkIn(
            'q-1',
            date: any(named: 'date'),
            proofType: any(named: 'proofType'),
            fileId: any(named: 'fileId'),
            textContent: any(named: 'textContent'),
            description: any(named: 'description'),
          )).thenThrow(QuestException("Vous avez déjà validé aujourd'hui"));

      await controller.checkIn('q-1');

      expect(controller.errorMessage.value, "Vous avez déjà validé aujourd'hui");
    });

    test('surfaces the no-ally 400 French message', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.checkIn(
            'q-1',
            date: any(named: 'date'),
            proofType: any(named: 'proofType'),
            fileId: any(named: 'fileId'),
            textContent: any(named: 'textContent'),
            description: any(named: 'description'),
          )).thenThrow(QuestException('Un allié accepté est requis pour soumettre une preuve'));

      await controller.checkIn('q-1', proofType: ProofType.photo, fileId: 'f-1');

      expect(controller.errorMessage.value, 'Un allié accepté est requis pour soumettre une preuve');
    });
  });

  group('QuestListController.refreshQuest', () {
    test('replaces the quest in place with the single-fetch result (allies included)', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      final withAllies = quest(id: 'q-1').copyWith();
      when(() => mockRepository.fetchQuest('q-1')).thenAnswer((_) async => withAllies);

      await controller.refreshQuest('q-1');

      expect(controller.findById('q-1'), same(withAllies));
    });
  });

  group('QuestListController.updateDescription', () {
    test('PATCHes and replaces the quest on success', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.updateQuest('q-1', {'description': 'Nouvelle description'}))
          .thenAnswer((_) async => quest(id: 'q-1'));

      final ok = await controller.updateDescription('q-1', 'Nouvelle description');

      expect(ok, isTrue);
      verify(() => mockRepository.updateQuest('q-1', {'description': 'Nouvelle description'}))
          .called(1);
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(() => mockRepository.updateQuest(any(), any()))
          .thenThrow(QuestException('Erreur'));

      final ok = await controller.updateDescription('q-1', 'x');

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Erreur');
    });
  });

  group('QuestListController.requestDeletion', () {
    test('removes the quest from the list when deleted immediately', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.requestDeletion('q-1')).thenAnswer(
        (_) async => const QuestDeletionOutcome(deleted: true, pending: false),
      );

      final outcome = await controller.requestDeletion('q-1');

      expect(outcome!.deleted, isTrue);
      expect(controller.findById('q-1'), isNull);
    });

    test('removes the quest from the list when cancelled+refunded', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.requestDeletion('q-1')).thenAnswer(
        (_) async => const QuestDeletionOutcome(deleted: false, pending: false, cancelled: true),
      );

      final outcome = await controller.requestDeletion('q-1');

      expect(outcome!.cancelled, isTrue);
      expect(controller.findById('q-1'), isNull);
    });

    test('keeps the quest and loads the pending request tally', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.requestDeletion('q-1')).thenAnswer(
        (_) async => const QuestDeletionOutcome(
          deleted: false,
          pending: true,
          requestId: 'req-1',
          votes: QuestDeletionVoteTally(approved: 0, total: 2),
        ),
      );
      when(() => mockRepository.fetchDeletionRequest('q-1')).thenAnswer(
        (_) async => const QuestDeletionRequest(
          id: 'req-1',
          status: QuestDeletionRequestStatus.pending,
          votes: QuestDeletionVoteTally(approved: 0, total: 2),
        ),
      );

      final outcome = await controller.requestDeletion('q-1');

      expect(outcome!.pending, isTrue);
      expect(controller.findById('q-1'), isNotNull);
      expect(controller.deletionRequests['q-1']!.votes.total, 2);
    });
  });

  group('QuestListController.voteOnDeletionRequest', () {
    test('votes then reloads the deletion request', () async {
      when(() => mockRepository.voteOnDeletionRequest('q-1', 'req-1', approve: true))
          .thenAnswer((_) async {});
      when(() => mockRepository.fetchDeletionRequest('q-1')).thenAnswer(
        (_) async => const QuestDeletionRequest(
          id: 'req-1',
          status: QuestDeletionRequestStatus.approved,
          votes: QuestDeletionVoteTally(approved: 2, total: 2),
        ),
      );

      await controller.voteOnDeletionRequest('q-1', 'req-1', approve: true);

      expect(controller.deletionRequests['q-1']!.status, QuestDeletionRequestStatus.approved);
    });
  });

  group('QuestListController.inviteAllies', () {
    test('invites then refreshes the quest, returning true', () async {
      controller.quests..clear()..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.inviteAllies('q-1', ['ally-1'])).thenAnswer((_) async {});
      when(() => mockRepository.fetchQuest('q-1')).thenAnswer((_) async => quest(id: 'q-1'));

      final ok = await controller.inviteAllies('q-1', ['ally-1']);

      expect(ok, isTrue);
      verify(() => mockRepository.fetchQuest('q-1')).called(1);
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(() => mockRepository.inviteAllies(any(), any()))
          .thenThrow(QuestException('Un ou plusieurs alliés ont déjà été invités sur cette quête'));

      final ok = await controller.inviteAllies('q-1', ['ally-1']);

      expect(ok, isFalse);
      expect(
        controller.errorMessage.value,
        'Un ou plusieurs alliés ont déjà été invités sur cette quête',
      );
    });
  });

  group('QuestListController.activeQuests / historyQuests', () {
    test('activeQuests includes active and pending-payment quests', () {
      controller.quests
        ..clear()
        ..addAll([
          quest(id: 'q-active', status: QuestStatus.active),
          quest(id: 'q-pending', status: QuestStatus.pendingPayment),
          quest(id: 'q-completed', status: QuestStatus.completed),
          quest(id: 'q-failed', status: QuestStatus.failed),
          quest(id: 'q-cancelled', status: QuestStatus.cancelled),
        ]);

      expect(
        controller.activeQuests.map((q) => q.id),
        containsAll(['q-active', 'q-pending']),
      );
      expect(controller.activeQuests, hasLength(2));
    });

    test('historyQuests includes completed, failed, and cancelled quests', () {
      controller.quests
        ..clear()
        ..addAll([
          quest(id: 'q-active', status: QuestStatus.active),
          quest(id: 'q-pending', status: QuestStatus.pendingPayment),
          quest(id: 'q-completed', status: QuestStatus.completed),
          quest(id: 'q-failed', status: QuestStatus.failed),
          quest(id: 'q-cancelled', status: QuestStatus.cancelled),
        ]);

      expect(
        controller.historyQuests.map((q) => q.id),
        containsAll(['q-completed', 'q-failed', 'q-cancelled']),
      );
      expect(controller.historyQuests, hasLength(3));
    });
  });

  group('QuestListController.loadPendingAllyInvitations', () {
    test('populates pendingAllyInvitations on success', () async {
      when(() => mockRepository.fetchMyAllyInvitations()).thenAnswer(
        (_) async => [
          QuestAllyInvitationSummary(
            questId: 'q-1',
            questTitle: 'Courir tous les jours',
            invitedAt: DateTime(2026, 7, 1),
          ),
        ],
      );

      await controller.loadPendingAllyInvitations();

      expect(controller.pendingAllyInvitations, hasLength(1));
      expect(controller.pendingAllyInvitations.single.questTitle, 'Courir tous les jours');
    });

    test('surfaces the backend error on failure', () async {
      when(() => mockRepository.fetchMyAllyInvitations())
          .thenThrow(QuestException('Non authentifié'));

      await controller.loadPendingAllyInvitations();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.pendingAllyInvitations, isEmpty);
    });
  });
}
