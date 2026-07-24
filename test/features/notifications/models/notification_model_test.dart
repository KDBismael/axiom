import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/notifications/models/notification_model.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses an unread notification', () {
      final notification = AppNotification.fromJson({
        'id': 'n-1',
        'type': 'validation_requested',
        'payload': {'questId': 'q-1', 'validationId': 'val-1'},
        'readAt': null,
        'createdAt': '2026-01-05T00:00:00.000Z',
      });

      expect(notification.id, 'n-1');
      expect(notification.type, 'validation_requested');
      expect(notification.payload['questId'], 'q-1');
      expect(notification.readAt, isNull);
      expect(notification.isUnread, isTrue);
      expect(notification.createdAt, DateTime.parse('2026-01-05T00:00:00.000Z'));
    });

    test('parses a read notification', () {
      final notification = AppNotification.fromJson({
        'id': 'n-2',
        'type': 'validation_decided',
        'payload': {},
        'readAt': '2026-01-06T00:00:00.000Z',
        'createdAt': '2026-01-05T00:00:00.000Z',
      });

      expect(notification.readAt, DateTime.parse('2026-01-06T00:00:00.000Z'));
      expect(notification.isUnread, isFalse);
    });
  });
}
