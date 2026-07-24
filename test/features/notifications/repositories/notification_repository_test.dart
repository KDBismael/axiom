import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/features/notifications/repositories/notification_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late NotificationRepository repository;

  final notificationJson = {
    'id': 'n-1',
    'type': 'validation_requested',
    'payload': {'questId': 'q-1'},
    'readAt': null,
    'createdAt': '2026-01-05T00:00:00.000Z',
  };

  setUp(() {
    mockClient = MockApiClient();
    repository = NotificationRepository(mockClient);
  });

  group('NotificationRepository.fetchNotifications', () {
    test('GETs /notifications without a filter', () async {
      when(() => mockClient.get<dynamic>('/notifications', query: any(named: 'query')))
          .thenAnswer((_) async => Response(statusCode: 200, body: [notificationJson]));

      final notifications = await repository.fetchNotifications();

      verify(() => mockClient.get<dynamic>('/notifications', query: null)).called(1);
      expect(notifications, hasLength(1));
    });

    test('GETs /notifications?unread=true when filtered', () async {
      when(() => mockClient.get<dynamic>('/notifications', query: any(named: 'query')))
          .thenAnswer((_) async => const Response(statusCode: 200, body: []));

      await repository.fetchNotifications(unread: true);

      verify(() => mockClient.get<dynamic>('/notifications', query: {'unread': 'true'}))
          .called(1);
    });
  });

  group('NotificationRepository.markRead', () {
    test('PATCHes /notifications/:id/read', () async {
      when(() => mockClient.patch<dynamic>('/notifications/n-1/read', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.markRead('n-1');

      verify(() => mockClient.patch<dynamic>('/notifications/n-1/read', any())).called(1);
    });
  });

  group('NotificationRepository.markAllRead', () {
    test('POSTs /notifications/read-all', () async {
      when(() => mockClient.post<dynamic>('/notifications/read-all', any()))
          .thenAnswer((_) async => const Response(statusCode: 200, body: {}));

      await repository.markAllRead();

      verify(() => mockClient.post<dynamic>('/notifications/read-all', any())).called(1);
    });
  });
}
