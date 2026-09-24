/// `GET /notifications` item. `type` is one of: ally_invite_accepted,
/// ally_request_received, ally_request_accepted, ally_request_declined,
/// ally_removed, validation_requested,
/// validation_decided, quest_completed, quest_failed,
/// quest_deadline_reminder, payment_succeeded, payment_failed, payout_sent,
/// refund_sent, payout_rejected, refund_rejected,
/// quest_ally_invite_received, quest_ally_invite_accepted,
/// quest_owner_invite_received, quest_owner_invite_accepted,
/// quest_owner_invite_declined, quest_owner_invite_expired,
/// quest_deletion_requested, quest_deletion_approved,
/// quest_deletion_rejected, quest_group_invite_received,
/// quest_group_member_joined, quest_group_invite_declined,
/// quest_pause_requested, quest_pause_decided.
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
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
