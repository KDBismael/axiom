import 'package:axiom/features/onboarding/models/first_quest_template.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 7, 9, 30);

  test('offers Sport 3×/semaine as a weekly quest with three sessions', () {
    final sport = firstQuestTemplates.firstWhere(
      (t) => t.title == 'Sport 3×/semaine',
    );
    final payload = sport.toPayload(now);

    expect(payload['frequency'], QuestFrequency.weekly.toJson());
    expect(payload['targetPerPeriod'], 3);
    expect(payload['durationDays'], 28);
  });

  test('every template is a solo quest with no stake and no proof', () {
    expect(firstQuestTemplates, hasLength(4));
    for (final template in firstQuestTemplates) {
      final payload = template.toPayload(now);
      expect(payload['hasStake'], isFalse, reason: template.title);
      expect(payload['requiresProof'], isFalse, reason: template.title);
      expect(payload.containsKey('allyUserIds'), isFalse);
      expect(payload.containsKey('inviteeId'), isFalse);
      expect((payload['description'] as String).trim(), isNotEmpty);
    }
  });

  test('starts today and ends after the template duration', () {
    final payload = firstQuestTemplates.first.toPayload(now);
    final start = DateTime.parse(payload['startDate'] as String);
    final deadline = DateTime.parse(payload['deadline'] as String);

    expect(start, now);
    expect(deadline.difference(start).inDays, payload['durationDays']);
  });
}
