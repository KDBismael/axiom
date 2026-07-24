import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/quest_ally_invitation.dart';
import 'package:axiom/features/quests/models/quest_model.dart';

void main() {
  group('QuestAllyInvitation.fromJson', () {
    test('parses the full quest terms for a staked quest', () {
      final invitation = QuestAllyInvitation.fromJson({
        'invitation': {'status': 'pending'},
        'quest': {
          'id': 'q-1',
          'title': 'Courir tous les jours',
          'description': '30 minutes de course',
          'frequency': 'daily',
          'durationDays': 30,
          'startDate': '2026-01-01T00:00:00.000Z',
          'deadline': '2026-01-31T00:00:00.000Z',
          'hasStake': true,
          'stakeAmountXof': '5000',
          'fundsDistribution': 'allies',
        },
      });

      expect(invitation.status, QuestAllyStatus.pending);
      expect(invitation.questId, 'q-1');
      expect(invitation.title, 'Courir tous les jours');
      expect(invitation.frequency, QuestFrequency.daily);
      expect(invitation.hasStake, isTrue);
      expect(invitation.stakeAmountXof, 5000.0);
      expect(invitation.fundsDistribution, FundsDistribution.allies);
    });

    test('handles an unstaked quest (nullable stake fields)', () {
      final invitation = QuestAllyInvitation.fromJson({
        'invitation': {'status': 'accepted'},
        'quest': {
          'id': 'q-1',
          'title': 'Lire 20 minutes',
          'description': 'Chaque soir',
          'frequency': 'daily',
          'durationDays': 14,
          'startDate': '2026-01-01T00:00:00.000Z',
          'deadline': '2026-01-15T00:00:00.000Z',
          'hasStake': false,
          'stakeAmountXof': null,
          'fundsDistribution': null,
        },
      });

      expect(invitation.status, QuestAllyStatus.accepted);
      expect(invitation.hasStake, isFalse);
      expect(invitation.stakeAmountXof, isNull);
      expect(invitation.fundsDistribution, isNull);
    });
  });
}
