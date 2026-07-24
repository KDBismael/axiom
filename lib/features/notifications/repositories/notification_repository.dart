import '../../../core/api/api_client.dart';
import '../models/notification_model.dart';

class NotificationException implements Exception {
  NotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotificationRepository {
  NotificationRepository(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> fetchNotifications({bool? unread}) async {
    final response = await _client.get(
      '/notifications',
      query: unread == null ? null : {'unread': unread.toString()},
    );
    if (!response.isOk || response.body == null) {
      throw NotificationException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    final response = await _client.patch('/notifications/$id/read', <String, dynamic>{});
    if (!response.isOk) {
      throw NotificationException(_extractMessage(response.body));
    }
  }

  Future<void> markAllRead() async {
    final response = await _client.post('/notifications/read-all', <String, dynamic>{});
    if (!response.isOk) {
      throw NotificationException(_extractMessage(response.body));
    }
  }

  String _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is List) return message.join('\n');
      if (message is String) return message;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
