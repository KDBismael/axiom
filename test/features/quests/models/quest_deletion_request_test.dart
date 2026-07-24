import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/quests/models/quest_deletion_request.dart';

void main() {
  group('QuestDeletionRequest.fromJson', () {
    test('parses a pending request with a vote tally', () {
      final request = QuestDeletionRequest.fromJson({
        'id': 'req-1',
        'status': 'pending',
        'votes': {'approved': 1, 'total': 2},
      });

      expect(request.id, 'req-1');
      expect(request.status, QuestDeletionRequestStatus.pending);
      expect(request.votes.approved, 1);
      expect(request.votes.total, 2);
    });

    test('parses approved and rejected statuses', () {
      final approved = QuestDeletionRequest.fromJson({
        'id': 'req-1',
        'status': 'approved',
        'votes': {'approved': 2, 'total': 2},
      });
      final rejected = QuestDeletionRequest.fromJson({
        'id': 'req-2',
        'status': 'rejected',
        'votes': {'approved': 1, 'total': 2},
      });

      expect(approved.status, QuestDeletionRequestStatus.approved);
      expect(rejected.status, QuestDeletionRequestStatus.rejected);
    });
  });
}
