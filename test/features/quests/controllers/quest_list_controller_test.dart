import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/quests/models/focus_session_model.dart';
import 'package:axiom/features/quests/models/quest_ally_invitation_summary.dart';
import 'package:axiom/features/quests/models/quest_deletion_request.dart';
import 'package:axiom/features/quests/models/quest_group_invitation_summary.dart';
import 'package:axiom/features/quests/models/quest_group_progress.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/models/quest_owner_invitation_summary.dart';
import 'package:axiom/features/quests/models/quest_pause_request.dart';
import 'package:axiom/features/quests/models/quest_pause_request_summary.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/quests/services/evidence_picker_service.dart';

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
      creatorId: 'user-1',
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
      when(
        () => mockRepository.fetchQuests(),
      ).thenAnswer((_) async => [quest(id: 'q-1'), quest(id: 'q-2')]);

      await controller.loadQuests();

      expect(controller.quests, hasLength(2));
      expect(controller.isLoading.value, isFalse);
    });

    test('surfaces the backend French message on failure', () async {
      when(
        () => mockRepository.fetchQuests(),
      ).thenThrow(QuestException('Non authentifié'));

      await controller.loadQuests();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.quests, isEmpty);
    });

    test('keeps existing dashboard content visible during refresh', () async {
      controller.quests
        ..clear()
        ..add(quest());
      controller.isLoading.value = false;
      final response = Completer<List<QuestModel>>();
      when(
        () => mockRepository.fetchQuests(),
      ).thenAnswer((_) => response.future);

      final refresh = controller.loadQuests();

      expect(controller.isLoading.value, isFalse);
      expect(controller.quests, hasLength(1));
      response.complete([quest(id: 'q-2')]);
      await refresh;
      expect(controller.quests.single.id, 'q-2');
    });
  });

  group('QuestListController.createQuest', () {
    test('sends the payload and appends the created quest', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenAnswer((_) async => quest(id: 'new-1'));

      final created = await controller.createQuest({'title': 'Gym'});

      final captured =
          verify(() => mockRepository.createQuest(captureAny())).captured.single
              as Map;
      expect(captured['title'], 'Gym');
      expect(controller.findById('new-1'), isNotNull);
      expect(created?.id, 'new-1');
    });

    test('returns null and does not add a quest on failure', () async {
      when(
        () => mockRepository.createQuest(any()),
      ).thenThrow(QuestException('Requête invalide'));

      final created = await controller.createQuest({'title': 'Gym'});

      expect(created, isNull);
      expect(controller.errorMessage.value, 'Requête invalide');
      expect(controller.quests, isEmpty);
    });

    test('a quest created with hasStake renders as pending_payment', () async {
      when(() => mockRepository.createQuest(any())).thenAnswer(
        (_) async => quest(
          id: 'stake-1',
          status: QuestStatus.pendingPayment,
          hasStake: true,
        ),
      );

      await controller.createQuest({'title': 'Gym', 'hasStake': true});

      expect(controller.findById('stake-1')!.isPendingPayment, isTrue);
    });
  });

  group('QuestListController.checkIn', () {
    test('refreshes the quest in place on success', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(
        () => mockRepository.checkIn(
          'q-1',
          date: any(named: 'date'),
          proofType: any(named: 'proofType'),
          fileId: any(named: 'fileId'),
          textContent: any(named: 'textContent'),
          description: any(named: 'description'),
        ),
      ).thenAnswer(
        (_) async => CheckInResult(
          checkIn: CheckIn(
            id: 'ci-1',
            questId: 'q-1',
            date: DateTime(2026, 1, 2),
          ),
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
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(
        () => mockRepository.checkIn(
          'q-1',
          date: any(named: 'date'),
          proofType: any(named: 'proofType'),
          fileId: any(named: 'fileId'),
          textContent: any(named: 'textContent'),
          description: any(named: 'description'),
        ),
      ).thenThrow(QuestException("Vous avez déjà validé aujourd'hui"));

      await controller.checkIn('q-1');

      expect(
        controller.errorMessage.value,
        "Vous avez déjà validé aujourd'hui",
      );
    });

    test('surfaces the no-ally 400 French message', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(
        () => mockRepository.checkIn(
          'q-1',
          date: any(named: 'date'),
          proofType: any(named: 'proofType'),
          fileId: any(named: 'fileId'),
          textContent: any(named: 'textContent'),
          description: any(named: 'description'),
        ),
      ).thenThrow(
        QuestException('Un allié accepté est requis pour soumettre une preuve'),
      );

      await controller.checkIn(
        'q-1',
        proofType: ProofType.photo,
        fileId: 'f-1',
      );

      expect(
        controller.errorMessage.value,
        'Un allié accepté est requis pour soumettre une preuve',
      );
    });

    test('forwards focusStartedAt/focusEndedAt to the repository', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      final startedAt = DateTime(2026, 1, 2, 9, 0);
      final endedAt = DateTime(2026, 1, 2, 9, 30);
      when(
        () => mockRepository.checkIn(
          'q-1',
          date: any(named: 'date'),
          proofType: any(named: 'proofType'),
          fileId: any(named: 'fileId'),
          textContent: any(named: 'textContent'),
          description: any(named: 'description'),
          focusStartedAt: startedAt,
          focusEndedAt: endedAt,
        ),
      ).thenAnswer(
        (_) async => CheckInResult(
          checkIn: CheckIn(
            id: 'ci-1',
            questId: 'q-1',
            date: DateTime(2026, 1, 2),
          ),
          streakDays: 1,
          progress: 0.1,
          currentPeriodCount: 1,
          targetPerPeriod: 1,
        ),
      );
      when(
        () => mockRepository.fetchQuest('q-1'),
      ).thenAnswer((_) async => quest(id: 'q-1'));

      await controller.checkIn(
        'q-1',
        focusStartedAt: startedAt,
        focusEndedAt: endedAt,
      );

      verify(
        () => mockRepository.checkIn(
          'q-1',
          date: any(named: 'date'),
          proofType: any(named: 'proofType'),
          fileId: any(named: 'fileId'),
          textContent: any(named: 'textContent'),
          description: any(named: 'description'),
          focusStartedAt: startedAt,
          focusEndedAt: endedAt,
        ),
      ).called(1);
    });
  });

  group('QuestListController.fetchFocusSessions', () {
    test('delegates to the repository', () async {
      when(() => mockRepository.fetchFocusSessions('q-1')).thenAnswer(
        (_) async => const FocusSessionHistory(sessions: [], todayMinutes: 30),
      );

      final history = await controller.fetchFocusSessions('q-1');

      expect(history.todayMinutes, 30);
    });
  });

  group('QuestListController.refreshQuest', () {
    test(
      'replaces the quest in place with the single-fetch result (allies included)',
      () async {
        controller.quests
          ..clear()
          ..addAll([quest(id: 'q-1')]);
        final withAllies = quest(id: 'q-1').copyWith();
        when(
          () => mockRepository.fetchQuest('q-1'),
        ).thenAnswer((_) async => withAllies);

        await controller.refreshQuest('q-1');

        expect(controller.findById('q-1'), same(withAllies));
      },
    );
  });

  group('QuestListController.updateDescription', () {
    test('PATCHes and replaces the quest on success', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(
        () => mockRepository.updateQuest('q-1', {
          'description': 'Nouvelle description',
        }),
      ).thenAnswer((_) async => quest(id: 'q-1'));

      final ok = await controller.updateDescription(
        'q-1',
        'Nouvelle description',
      );

      expect(ok, isTrue);
      verify(
        () => mockRepository.updateQuest('q-1', {
          'description': 'Nouvelle description',
        }),
      ).called(1);
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(
        () => mockRepository.updateQuest(any(), any()),
      ).thenThrow(QuestException('Erreur'));

      final ok = await controller.updateDescription('q-1', 'x');

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Erreur');
    });
  });

  group('QuestListController.requestDeletion', () {
    test('removes the quest from the list when deleted immediately', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.requestDeletion('q-1')).thenAnswer(
        (_) async => const QuestDeletionOutcome(deleted: true, pending: false),
      );

      final outcome = await controller.requestDeletion('q-1');

      expect(outcome!.deleted, isTrue);
      expect(controller.findById('q-1'), isNull);
    });

    test('removes the quest from the list when cancelled+refunded', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(() => mockRepository.requestDeletion('q-1')).thenAnswer(
        (_) async => const QuestDeletionOutcome(
          deleted: false,
          pending: false,
          cancelled: true,
        ),
      );

      final outcome = await controller.requestDeletion('q-1');

      expect(outcome!.cancelled, isTrue);
      expect(controller.findById('q-1'), isNull);
    });

    test('keeps the quest and loads the pending request tally', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
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
      when(
        () =>
            mockRepository.voteOnDeletionRequest('q-1', 'req-1', approve: true),
      ).thenAnswer((_) async {});
      when(() => mockRepository.fetchDeletionRequest('q-1')).thenAnswer(
        (_) async => const QuestDeletionRequest(
          id: 'req-1',
          status: QuestDeletionRequestStatus.approved,
          votes: QuestDeletionVoteTally(approved: 2, total: 2),
        ),
      );

      await controller.voteOnDeletionRequest('q-1', 'req-1', approve: true);

      expect(
        controller.deletionRequests['q-1']!.status,
        QuestDeletionRequestStatus.approved,
      );
    });
  });

  group('QuestListController.inviteAllies', () {
    test('invites then refreshes the quest, returning true', () async {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-1')]);
      when(
        () => mockRepository.inviteAllies('q-1', ['ally-1']),
      ).thenAnswer((_) async {});
      when(
        () => mockRepository.fetchQuest('q-1'),
      ).thenAnswer((_) async => quest(id: 'q-1'));

      final ok = await controller.inviteAllies('q-1', ['ally-1']);

      expect(ok, isTrue);
      verify(() => mockRepository.fetchQuest('q-1')).called(1);
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(() => mockRepository.inviteAllies(any(), any())).thenThrow(
        QuestException(
          'Un ou plusieurs alliés ont déjà été invités sur cette quête',
        ),
      );

      final ok = await controller.inviteAllies('q-1', ['ally-1']);

      expect(ok, isFalse);
      expect(
        controller.errorMessage.value,
        'Un ou plusieurs alliés ont déjà été invités sur cette quête',
      );
    });
  });

  group('QuestListController.activeQuests / historyQuests', () {
    test(
      'activeQuests includes active, paused, pending-payment, and pending-owner-acceptance quests',
      () {
        controller.quests
          ..clear()
          ..addAll([
            quest(id: 'q-active', status: QuestStatus.active),
            quest(id: 'q-paused', status: QuestStatus.paused),
            quest(id: 'q-pending', status: QuestStatus.pendingPayment),
            quest(
              id: 'q-pending-owner',
              status: QuestStatus.pendingOwnerAcceptance,
            ),
            quest(id: 'q-completed', status: QuestStatus.completed),
            quest(id: 'q-failed', status: QuestStatus.failed),
            quest(id: 'q-cancelled', status: QuestStatus.cancelled),
          ]);

        expect(
          controller.activeQuests.map((q) => q.id),
          containsAll(['q-active', 'q-paused', 'q-pending', 'q-pending-owner']),
        );
        expect(controller.activeQuests, hasLength(4));
      },
    );

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

  group('QuestListController.totalStakeAmount', () {
    test('sums only active quests\' stakes, not finished ones', () {
      controller.quests
        ..clear()
        ..addAll([
          quest(
            id: 'q-active',
            status: QuestStatus.active,
            hasStake: true,
            stakeAmountXof: 1000,
          ),
          quest(
            id: 'q-completed',
            status: QuestStatus.completed,
            hasStake: true,
            stakeAmountXof: 100000,
          ),
          quest(
            id: 'q-failed',
            status: QuestStatus.failed,
            hasStake: true,
            stakeAmountXof: 1000,
          ),
        ]);

      expect(controller.totalStakeAmount, 1000);
    });

    test('includes pending-payment and pending-owner-acceptance stakes', () {
      controller.quests
        ..clear()
        ..addAll([
          quest(
            id: 'q-active',
            status: QuestStatus.active,
            hasStake: true,
            stakeAmountXof: 1000,
          ),
          quest(
            id: 'q-pending',
            status: QuestStatus.pendingPayment,
            hasStake: true,
            stakeAmountXof: 2000,
          ),
        ]);

      expect(controller.totalStakeAmount, 3000);
    });

    test('is zero with no active stakes', () {
      controller.quests
        ..clear()
        ..addAll([quest(id: 'q-completed', status: QuestStatus.completed)]);

      expect(controller.totalStakeAmount, 0);
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
      expect(
        controller.pendingAllyInvitations.single.questTitle,
        'Courir tous les jours',
      );
    });

    test('surfaces the backend error on failure', () async {
      when(
        () => mockRepository.fetchMyAllyInvitations(),
      ).thenThrow(QuestException('Non authentifié'));

      await controller.loadPendingAllyInvitations();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.pendingAllyInvitations, isEmpty);
    });
  });

  group('QuestListController.loadPendingOwnerInvitations', () {
    test('populates pendingOwnerInvitations on success', () async {
      when(() => mockRepository.fetchMyOwnerInvitations()).thenAnswer(
        (_) async => [
          QuestOwnerInvitationSummary(
            questId: 'q-1',
            questTitle: 'Courir pour un ami',
            invitedAt: DateTime(2026, 7, 1),
          ),
        ],
      );

      await controller.loadPendingOwnerInvitations();

      expect(controller.pendingOwnerInvitations, hasLength(1));
      expect(
        controller.pendingOwnerInvitations.single.questTitle,
        'Courir pour un ami',
      );
    });

    test('surfaces the backend error on failure', () async {
      when(
        () => mockRepository.fetchMyOwnerInvitations(),
      ).thenThrow(QuestException('Non authentifié'));

      await controller.loadPendingOwnerInvitations();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.pendingOwnerInvitations, isEmpty);
    });
  });

  group('QuestListController.createQuestGroup', () {
    test('sends the payload and appends the created quest', () async {
      when(
        () => mockRepository.createQuestGroup(any()),
      ).thenAnswer((_) async => quest(id: 'group-quest-1'));

      final created = await controller.createQuestGroup({
        'title': 'Défi 30 jours',
      });

      final captured =
          verify(
                () => mockRepository.createQuestGroup(captureAny()),
              ).captured.single
              as Map;
      expect(captured['title'], 'Défi 30 jours');
      expect(controller.findById('group-quest-1'), isNotNull);
      expect(created?.id, 'group-quest-1');
    });

    test('returns null and does not add a quest on failure', () async {
      when(
        () => mockRepository.createQuestGroup(any()),
      ).thenThrow(QuestException('Requête invalide'));

      final created = await controller.createQuestGroup({
        'title': 'Défi 30 jours',
      });

      expect(created, isNull);
      expect(controller.errorMessage.value, 'Requête invalide');
      expect(controller.quests, isEmpty);
    });
  });

  group('QuestListController.loadGroupProgress', () {
    test('populates groupProgress on success', () async {
      when(() => mockRepository.fetchGroupProgress('group-1')).thenAnswer(
        (_) async => const QuestGroupProgress(
          groupId: 'group-1',
          groupTitle: 'Défi 30 jours',
          creatorId: 'user-1',
          members: [
            QuestGroupMemberProgress(
              userId: 'user-1',
              questId: 'q-1',
              status: QuestStatus.active,
              progress: 0.5,
              streakDays: 3,
            ),
          ],
        ),
      );

      await controller.loadGroupProgress('group-1');

      expect(controller.groupProgress['group-1']?.members, hasLength(1));
      expect(controller.groupProgress['group-1']?.members.single.streakDays, 3);
    });

    test('surfaces the backend error on failure', () async {
      when(
        () => mockRepository.fetchGroupProgress('group-1'),
      ).thenThrow(QuestException('Vous ne faites pas partie de ce groupe'));

      await controller.loadGroupProgress('group-1');

      expect(
        controller.errorMessage.value,
        'Vous ne faites pas partie de ce groupe',
      );
      expect(controller.groupProgress.containsKey('group-1'), isFalse);
    });
  });

  group('QuestListController.inviteGroupMembers', () {
    test('invites and returns true', () async {
      when(
        () => mockRepository.inviteGroupMembers('group-1', ['user-2']),
      ).thenAnswer((_) async {});

      final ok = await controller.inviteGroupMembers('group-1', ['user-2']);

      expect(ok, isTrue);
      verify(
        () => mockRepository.inviteGroupMembers('group-1', ['user-2']),
      ).called(1);
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(() => mockRepository.inviteGroupMembers(any(), any())).thenThrow(
        QuestException(
          'Un ou plusieurs utilisateurs font déjà partie de cette quête collective',
        ),
      );

      final ok = await controller.inviteGroupMembers('group-1', ['user-2']);

      expect(ok, isFalse);
      expect(
        controller.errorMessage.value,
        'Un ou plusieurs utilisateurs font déjà partie de cette quête collective',
      );
    });
  });

  group('QuestListController.loadPendingGroupInvitations', () {
    test('populates pendingGroupInvitations on success', () async {
      when(() => mockRepository.fetchMyGroupInvitations()).thenAnswer(
        (_) async => [
          QuestGroupInvitationSummary(
            groupId: 'group-1',
            groupTitle: 'Défi 30 jours',
            invitedAt: DateTime(2026, 7, 1),
          ),
        ],
      );

      await controller.loadPendingGroupInvitations();

      expect(controller.pendingGroupInvitations, hasLength(1));
      expect(
        controller.pendingGroupInvitations.single.groupTitle,
        'Défi 30 jours',
      );
    });

    test('surfaces the backend error on failure', () async {
      when(
        () => mockRepository.fetchMyGroupInvitations(),
      ).thenThrow(QuestException('Non authentifié'));

      await controller.loadPendingGroupInvitations();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.pendingGroupInvitations, isEmpty);
    });
  });

  group('QuestListController.requestPause', () {
    test(
      'sends a text-proof pause request, caches it, and refreshes the quest',
      () async {
        controller.quests
          ..clear()
          ..addAll([quest(id: 'q-1')]);
        when(
          () => mockRepository.requestPause(
            'q-1',
            proofType: ProofType.text,
            textContent: 'Grippe',
            description: 'Grippe',
          ),
        ).thenAnswer(
          (_) async => QuestPauseRequest(
            id: 'pr-1',
            status: QuestPauseRequestStatus.approved,
            createdAt: DateTime(2026, 7, 1),
          ),
        );
        when(
          () => mockRepository.fetchQuest('q-1'),
        ).thenAnswer((_) async => quest(id: 'q-1', status: QuestStatus.paused));

        final ok = await controller.requestPause('q-1', reason: 'Grippe');

        expect(ok, isTrue);
        expect(controller.pauseRequests['q-1']?.id, 'pr-1');
        expect(controller.findById('q-1')!.status, QuestStatus.paused);
      },
    );

    test('uploads optional photo before requesting pause', () async {
      final photo = PickedEvidence(
        bytes: Uint8List.fromList([1, 2]),
        sizeBytes: 2,
        filename: 'preuve.jpg',
        mimeType: 'image/jpeg',
      );
      when(
        () => mockRepository.uploadEvidenceFile(photo),
      ).thenAnswer((_) async => 'file-1');
      when(
        () => mockRepository.requestPause(
          'q-1',
          proofType: ProofType.photo,
          fileIds: ['file-1'],
          description: 'Grippe',
        ),
      ).thenAnswer(
        (_) async => QuestPauseRequest(
          id: 'pr-1',
          status: QuestPauseRequestStatus.pending,
          createdAt: DateTime(2026, 7, 1),
        ),
      );
      when(
        () => mockRepository.fetchQuest('q-1'),
      ).thenAnswer((_) async => quest());

      expect(
        await controller.requestPause('q-1', reason: 'Grippe', photo: photo),
        isTrue,
      );
      verifyInOrder([
        () => mockRepository.uploadEvidenceFile(photo),
        () => mockRepository.requestPause(
          'q-1',
          proofType: ProofType.photo,
          fileIds: ['file-1'],
          description: 'Grippe',
        ),
      ]);
    });

    test('does not request pause if optional photo upload fails', () async {
      final photo = PickedEvidence(
        bytes: Uint8List.fromList([1]),
        sizeBytes: 1,
        filename: 'preuve.jpg',
        mimeType: 'image/jpeg',
      );
      when(
        () => mockRepository.uploadEvidenceFile(photo),
      ).thenThrow(QuestException('Envoi impossible'));

      expect(
        await controller.requestPause('q-1', reason: 'Grippe', photo: photo),
        isFalse,
      );
      expect(controller.errorMessage.value, 'Envoi impossible');
      verifyNever(
        () => mockRepository.requestPause(
          any(),
          proofType: any(named: 'proofType'),
        ),
      );
    });

    test('surfaces the backend error and returns false on failure', () async {
      when(
        () => mockRepository.requestPause(
          any(),
          proofType: any(named: 'proofType'),
          textContent: any(named: 'textContent'),
          description: any(named: 'description'),
        ),
      ).thenThrow(QuestException('Une demande de pause est déjà en attente'));

      final ok = await controller.requestPause('q-1', reason: 'Grippe');

      expect(ok, isFalse);
      expect(
        controller.errorMessage.value,
        'Une demande de pause est déjà en attente',
      );
    });
  });

  group('QuestListController.decidePauseRequest', () {
    test(
      'decides then reloads pending pause requests, returning true',
      () async {
        when(
          () => mockRepository.decidePauseRequest(
            'q-1',
            'pr-1',
            approve: true,
            comment: null,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockRepository.fetchMyPauseRequests(),
        ).thenAnswer((_) async => []);

        final ok = await controller.decidePauseRequest(
          'q-1',
          'pr-1',
          approve: true,
        );

        expect(ok, isTrue);
        verify(() => mockRepository.fetchMyPauseRequests()).called(1);
      },
    );

    test('surfaces the backend error and returns false on failure', () async {
      when(
        () => mockRepository.decidePauseRequest(
          any(),
          any(),
          approve: any(named: 'approve'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(QuestException('Cette demande a déjà été traitée'));

      final ok = await controller.decidePauseRequest(
        'q-1',
        'pr-1',
        approve: true,
      );

      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Cette demande a déjà été traitée');
    });
  });

  group('QuestListController.resumeQuest', () {
    test(
      'replaces the quest in place and clears its cached pause request',
      () async {
        controller.quests
          ..clear()
          ..addAll([quest(id: 'q-1', status: QuestStatus.paused)]);
        controller.pauseRequests['q-1'] = QuestPauseRequest(
          id: 'pr-1',
          status: QuestPauseRequestStatus.approved,
          createdAt: DateTime(2026, 7, 1),
        );
        when(
          () => mockRepository.resumeQuest('q-1'),
        ).thenAnswer((_) async => quest(id: 'q-1', status: QuestStatus.active));

        final ok = await controller.resumeQuest('q-1');

        expect(ok, isTrue);
        expect(controller.findById('q-1')!.status, QuestStatus.active);
        expect(controller.pauseRequests.containsKey('q-1'), isFalse);
      },
    );

    test('surfaces the backend error and returns false on failure', () async {
      when(
        () => mockRepository.resumeQuest(any()),
      ).thenThrow(QuestException("Cette quête n'est pas en pause"));

      final ok = await controller.resumeQuest('q-1');

      expect(ok, isFalse);
      expect(controller.errorMessage.value, "Cette quête n'est pas en pause");
    });
  });

  group('QuestListController.loadPendingPauseRequests', () {
    test('populates pendingPauseRequests on success', () async {
      when(() => mockRepository.fetchMyPauseRequests()).thenAnswer(
        (_) async => [
          QuestPauseRequestSummary(
            requestId: 'pr-1',
            questId: 'q-1',
            questTitle: 'Courir tous les jours',
            createdAt: DateTime(2026, 7, 1),
          ),
        ],
      );

      await controller.loadPendingPauseRequests();

      expect(controller.pendingPauseRequests, hasLength(1));
      expect(
        controller.pendingPauseRequests.single.questTitle,
        'Courir tous les jours',
      );
    });

    test('surfaces the backend error on failure', () async {
      when(
        () => mockRepository.fetchMyPauseRequests(),
      ).thenThrow(QuestException('Non authentifié'));

      await controller.loadPendingPauseRequests();

      expect(controller.errorMessage.value, 'Non authentifié');
      expect(controller.pendingPauseRequests, isEmpty);
    });
  });
}
