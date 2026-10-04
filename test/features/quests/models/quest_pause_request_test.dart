import 'package:axiom/features/quests/models/quest_pause_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the reason and optional photo from a pause request', () {
    final request = QuestPauseRequest.fromJson({
      'id': 'pause-1',
      'status': 'pending',
      'createdAt': '2026-09-25T12:00:00.000Z',
      'description': 'Maladie',
      'fileIds': ['file-1'],
    });

    expect(request.reason, 'Maladie');
    expect(request.fileIds, ['file-1']);
  });

  test('reads the reason from existing text-only pause requests', () {
    final request = QuestPauseRequest.fromJson({
      'id': 'pause-2',
      'status': 'pending',
      'createdAt': '2026-09-25T12:00:00.000Z',
      'textContent': 'Grippe',
    });

    expect(request.reason, 'Grippe');
    expect(request.fileIds, isEmpty);
  });
}
