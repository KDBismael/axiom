import '../models/quest_model.dart';

/// The "kind" eyebrow shown on a quest card — not a backend field, derived
/// from data already on [QuestModel]: a quest whose creator isn't the
/// current user was sponsored by someone else; otherwise it's solo or
/// collective depending on [QuestModel.groupId].
enum QuestKind { solo, collective, offerte }

QuestKind questKindFor(QuestModel quest, String? currentUserId) {
  if (currentUserId != null && quest.creatorId != currentUserId) {
    return QuestKind.offerte;
  }
  if (quest.isCollective) return QuestKind.collective;
  return QuestKind.solo;
}

const questKindLabels = {
  QuestKind.solo: 'SOLO',
  QuestKind.collective: 'COLLECTIVE',
  QuestKind.offerte: 'OFFERTE',
};
