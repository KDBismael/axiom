import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/quest_model.dart';

void main() {
  final json = {
    'id': 'q-1',
    'title': 'Gym 3x par semaine',
    'description': 'Ne jamais sauter une séance.',
    'frequency': 'weekly',
    'durationDays': 30,
    'targetPerPeriod': 1,
    'startDate': '2026-01-01T00:00:00.000Z',
    'deadline': '2026-02-01T00:00:00.000Z',
    'gracePeriodDays': 2,
    'riskLevel': 'medium',
    'requiresProof': true,
    'successThresholdPercent': 80,
    'hasStake': true,
    'stakeAmountXof': 5000.0,
    'fundsDistribution': 'allies',
    'status': 'active',
    'progress': 0.42,
    'streakDays': 3,
  };

  group('QuestModel.fromJson', () {
    test('parses the full backend shape', () {
      final quest = QuestModel.fromJson(json);

      expect(quest.id, 'q-1');
      expect(quest.title, 'Gym 3x par semaine');
      expect(quest.description, 'Ne jamais sauter une séance.');
      expect(quest.frequency, QuestFrequency.weekly);
      expect(quest.durationDays, 30);
      expect(quest.targetPerPeriod, 1);
      expect(quest.startDate, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(quest.deadline, DateTime.parse('2026-02-01T00:00:00.000Z'));
      expect(quest.gracePeriodDays, 2);
      expect(quest.riskLevel, QuestRiskLevel.medium);
      expect(quest.requiresProof, isTrue);
      expect(quest.successThresholdPercent, 80);
      expect(quest.hasStake, isTrue);
      expect(quest.stakeAmountXof, 5000.0);
      expect(quest.fundsDistribution, FundsDistribution.allies);
      expect(quest.status, QuestStatus.active);
      expect(quest.progress, 0.42);
      expect(quest.streakDays, 3);
    });

    test('parses status: pending_payment', () {
      final quest = QuestModel.fromJson({...json, 'status': 'pending_payment'});
      expect(quest.status, QuestStatus.pendingPayment);
    });

    test('handles a quest with no stake (nullable fields)', () {
      final quest = QuestModel.fromJson({
        ...json,
        'hasStake': false,
        'stakeAmountXof': null,
        'fundsDistribution': null,
      });
      expect(quest.hasStake, isFalse);
      expect(quest.stakeAmountXof, isNull);
      expect(quest.fundsDistribution, isNull);
    });

    test('parses stakeAmountXof when the backend sends a Decimal-as-string', () {
      final quest = QuestModel.fromJson({...json, 'stakeAmountXof': '5000'});
      expect(quest.stakeAmountXof, 5000.0);
    });

    test('parses targetPerPeriod > 1', () {
      final quest = QuestModel.fromJson({...json, 'targetPerPeriod': 3});
      expect(quest.targetPerPeriod, 3);
    });

    test('parses status: cancelled', () {
      final quest = QuestModel.fromJson({...json, 'status': 'cancelled'});
      expect(quest.status, QuestStatus.cancelled);
    });

    test('defaults allies to an empty list when omitted (list endpoint)', () {
      final quest = QuestModel.fromJson(json);
      expect(quest.allies, isEmpty);
    });

    test('parses embedded allies (single-quest endpoint)', () {
      final quest = QuestModel.fromJson({
        ...json,
        'allies': [
          {
            'userId': 'u-2',
            'firstName': 'Awa',
            'lastName': 'Koné',
            'avatarUrl': null,
            'status': 'accepted',
          },
          {
            'userId': 'u-3',
            'firstName': 'Issa',
            'lastName': 'Traoré',
            'avatarUrl': '/files/f-1',
            'status': 'pending',
          },
        ],
      });

      expect(quest.allies, hasLength(2));
      expect(quest.allies[0].userId, 'u-2');
      expect(quest.allies[0].status, QuestAllyStatus.accepted);
      expect(quest.allies[1].status, QuestAllyStatus.pending);
      expect(quest.allies[1].avatarUrl, '/files/f-1');
    });
  });

  group('QuestModel computed getters', () {
    test('isPendingPayment / isActive reflect status', () {
      final pending = QuestModel.fromJson({...json, 'status': 'pending_payment'});
      final active = QuestModel.fromJson({...json, 'status': 'active'});
      expect(pending.isPendingPayment, isTrue);
      expect(active.isPendingPayment, isFalse);
      expect(active.isActive, isTrue);
    });

    test('isFinished is true for completed, failed, and cancelled quests only', () {
      final completed = QuestModel.fromJson({...json, 'status': 'completed'});
      final failed = QuestModel.fromJson({...json, 'status': 'failed'});
      final cancelled = QuestModel.fromJson({...json, 'status': 'cancelled'});
      final active = QuestModel.fromJson({...json, 'status': 'active'});
      final pending = QuestModel.fromJson({...json, 'status': 'pending_payment'});

      expect(completed.isFinished, isTrue);
      expect(failed.isFinished, isTrue);
      expect(cancelled.isFinished, isTrue);
      expect(active.isFinished, isFalse);
      expect(pending.isFinished, isFalse);
    });
  });
}
