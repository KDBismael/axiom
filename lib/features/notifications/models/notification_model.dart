/// `GET /notifications` item. `type` is one of: ally_invite_accepted,
/// ally_request_received, ally_request_accepted, validation_requested,
/// validation_decided, quest_completed, quest_failed,
/// quest_deadline_reminder, payment_succeeded, payment_failed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: json['payload'] == null
          ? const {}
          : Map<String, dynamic>.from(json['payload'] as Map),
      readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
