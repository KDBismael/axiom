import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/notifications/controllers/notification_controller.dart';
import 'package:axiom/features/notifications/models/notification_model.dart';
import 'package:axiom/features/notifications/repositories/notification_repository.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepository;
  late NotificationController controller;

  AppNotification notification({String id = 'n-1', DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: 'validation_requested',
      payload: const {},
      readAt: readAt,
      createdAt: DateTime(2026, 1, 5),
    );
  }

  setUp(() {
    mockRepository = MockNotificationRepository();
    controller = NotificationController(mockRepository);
  });

  group('NotificationController.loadNotifications', () {
    test('populates notifications and computes unreadCount', () async {
      when(() => mockRepository.fetchNotifications(unread: any(named: 'unread'))).thenAnswer(
        (_) async => [
          notification(id: 'n-1'),
          notification(id: 'n-2', readAt: DateTime(2026, 1, 6)),
        ],
      );

      await controller.loadNotifications();

      expect(controller.notifications, hasLength(2));
      expect(controller.unreadCount, 1);
    });
  });

  group('NotificationController.markRead', () {
    test('marks the notification read locally without a full reload', () async {
      when(() => mockRepository.fetchNotifications(unread: any(named: 'unread')))
          .thenAnswer((_) async => [notification(id: 'n-1')]);
      await controller.loadNotifications();

      when(() => mockRepository.markRead('n-1')).thenAnswer((_) async {});

      await controller.markRead('n-1');

      verify(() => mockRepository.markRead('n-1')).called(1);
      expect(controller.notifications.single.isUnread, isFalse);
    });
  });

  group('NotificationController.markAllRead', () {
    test('marks every notification read locally', () async {
      when(() => mockRepository.fetchNotifications(unread: any(named: 'unread')))
          .thenAnswer((_) async => [notification(id: 'n-1'), notification(id: 'n-2')]);
      await controller.loadNotifications();

      when(() => mockRepository.markAllRead()).thenAnswer((_) async {});

      await controller.markAllRead();

      verify(() => mockRepository.markAllRead()).called(1);
      expect(controller.unreadCount, 0);
    });
  });
}
