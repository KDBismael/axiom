import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/quest_ally_invitation_summary.dart';

void main() {
  test('QuestAllyInvitationSummary.fromJson parses a pending invitation row', () {
    final summary = QuestAllyInvitationSummary.fromJson({
      'questId': 'quest-1',
      'questTitle': 'Courir tous les jours',
      'invitedAt': '2026-07-01T00:00:00.000Z',
    });

    expect(summary.questId, 'quest-1');
    expect(summary.questTitle, 'Courir tous les jours');
    expect(summary.invitedAt, DateTime.parse('2026-07-01T00:00:00.000Z'));
  });
}
