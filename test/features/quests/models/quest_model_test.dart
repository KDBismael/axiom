import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/quest_model.dart';

void main() {
  group('QuestModel', () {
    const base = QuestModel(
      id: '1',
      title: 'Gym 3x per week',
      durationDays: 30,
      frequency: QuestFrequency.weekly,
      progress: 7,
      total: 12,
    );

    test('description/stakeAmount/pendingValidation default sensibly', () {
      expect(base.description, '');
      expect(base.stakeAmount, isNull);
      expect(base.pendingValidation, isFalse);
    });

    test('accepts explicit values for the new fields', () {
      const quest = QuestModel(
        id: '1',
        title: 'Gym 3x per week',
        durationDays: 30,
        frequency: QuestFrequency.weekly,
        progress: 7,
        total: 12,
        description: 'Consistency is the only metric.',
        stakeAmount: 100,
        pendingValidation: true,
      );
      expect(quest.description, 'Consistency is the only metric.');
      expect(quest.stakeAmount, 100);
      expect(quest.pendingValidation, isTrue);
    });

    test('copyWith preserves the new fields when not overridden', () {
      const quest = QuestModel(
        id: '1',
        title: 'Gym 3x per week',
        durationDays: 30,
        frequency: QuestFrequency.weekly,
        progress: 7,
        total: 12,
        description: 'Consistency is the only metric.',
        stakeAmount: 100,
        pendingValidation: true,
      );
      final updated = quest.copyWith(progress: 8);
      expect(updated.progress, 8);
      expect(updated.description, 'Consistency is the only metric.');
      expect(updated.stakeAmount, 100);
      expect(updated.pendingValidation, isTrue);
    });
  });
}
