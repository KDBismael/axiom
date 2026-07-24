/// An accepted ally — `GET /allies`.
class Ally {
  const Ally({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  factory Ally.fromJson(Map<String, dynamic> json) {
    return Ally(
      id: json['userId'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
