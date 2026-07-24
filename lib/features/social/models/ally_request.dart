enum AllyRequestDirection {
  incoming,
  outgoing;

  factory AllyRequestDirection.fromJson(String value) =>
      AllyRequestDirection.values.firstWhere((v) => v.name == value);
}

enum AllyRequestStatus {
  pending,
  accepted,
  declined;

  factory AllyRequestStatus.fromJson(String value) =>
      AllyRequestStatus.values.firstWhere((v) => v.name == value);
}

class AllyRequestUser {
  const AllyRequestUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  factory AllyRequestUser.fromJson(Map<String, dynamic> json) {
    return AllyRequestUser(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// A pending/decided direct ally request — `GET /allies/requests`.
class AllyRequest {
  const AllyRequest({
    required this.id,
    required this.direction,
    required this.status,
    required this.otherUser,
  });

  final String id;
  final AllyRequestDirection direction;
  final AllyRequestStatus status;
  final AllyRequestUser otherUser;

  factory AllyRequest.fromJson(Map<String, dynamic> json) {
    return AllyRequest(
      id: json['id'] as String,
      direction: AllyRequestDirection.fromJson(json['direction'] as String),
      status: AllyRequestStatus.fromJson(json['status'] as String),
      otherUser: AllyRequestUser.fromJson(json['otherUser'] as Map<String, dynamic>),
    );
  }
}
