import 'dart:convert';

import 'package:axiom/features/notifications/services/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PushEnvelope', () {
    test('parses the backend FCM data contract', () {
      final envelope = PushEnvelope.fromData({
        'notificationId': 'n-1',
        'type': 'quest_completed',
        'payload': '{"questId":"q-1"}',
      });

      expect(envelope.notificationId, 'n-1');
      expect(envelope.type, 'quest_completed');
      expect(envelope.payload, {'questId': 'q-1'});
    });

    test('round-trips through the local-notification payload', () {
      const original = PushEnvelope(
        notificationId: 'n-1',
        type: 'validation_requested',
        payload: {'evidenceId': 'e-1'},
      );

      final decoded = PushEnvelope.fromData(
        Map<String, dynamic>.from((jsonDecode(original.encode()) as Map)),
      );
      expect(decoded.type, original.type);
      expect(decoded.payload, original.payload);
    });

    test('rejects a message without a type', () {
      expect(
        () => PushEnvelope.fromData({'payload': '{}'}),
        throwsFormatException,
      );
    });
  });

  group('questIdToRefresh', () {
    test('returns the quest for an accepted quest-ally invitation', () {
      expect(
        questIdToRefresh(
          const PushEnvelope(
            type: 'quest_ally_invite_accepted',
            payload: {'questId': 'quest-1'},
          ),
        ),
        'quest-1',
      );
    });

    test('ignores unrelated and malformed notifications', () {
      expect(
        questIdToRefresh(
          const PushEnvelope(type: 'ally_request_accepted', payload: {}),
        ),
        isNull,
      );
      expect(
        questIdToRefresh(
          const PushEnvelope(type: 'quest_ally_invite_accepted', payload: {}),
        ),
        isNull,
      );
    });
  });
}
