enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired;

  factory InvitationStatus.fromJson(String value) =>
      InvitationStatus.values.firstWhere((v) => v.name == value);
}

class AllyInvitation {
  const AllyInvitation({
    required this.id,
    required this.status,
    required this.expiresAt,
    this.token,
    this.deepLink,
  });

  final String id;

  /// Only present in the response right after creation — the persisted row
  /// only stores a hash, and the list endpoint never returns it.
  final String? token;

  /// Same as [token]: only present right after creation.
  final String? deepLink;

  final InvitationStatus status;
  final DateTime expiresAt;

  factory AllyInvitation.fromJson(Map<String, dynamic> json) {
    return AllyInvitation(
      id: json['id'] as String,
      token: json['token'] as String?,
      deepLink: json['deepLink'] as String?,
      status: InvitationStatus.fromJson(json['status'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
