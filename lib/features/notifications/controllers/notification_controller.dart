import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationController extends GetxController {
  NotificationController(this._repository);

  final NotificationRepository _repository;

  final notifications = <AppNotification>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications({bool? unread}) async {
    isLoading.value = true;
    try {
      notifications.assignAll(await _repository.fetchNotifications(unread: unread));
    } on NotificationException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repository.markRead(id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final current = notifications[index];
        notifications[index] = AppNotification(
          id: current.id,
          type: current.type,
          payload: current.payload,
          createdAt: current.createdAt,
          readAt: DateTime.now(),
        );
      }
    } on NotificationException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead();
      final now = DateTime.now();
      notifications.assignAll([
        for (final n in notifications)
          AppNotification(
            id: n.id,
            type: n.type,
            payload: n.payload,
            createdAt: n.createdAt,
            readAt: n.readAt ?? now,
          ),
      ]);
    } on NotificationException catch (e) {
      errorMessage.value = e.message;
    }
  }
}
