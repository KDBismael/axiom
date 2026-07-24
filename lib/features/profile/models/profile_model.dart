enum ProfilePrivacyLevel {
  standard,
  private;

  factory ProfilePrivacyLevel.fromJson(String value) {
    return ProfilePrivacyLevel.values.firstWhere((v) => v.name == value);
  }

  String toJson() => name;
}

class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    required this.language,
    required this.notificationsEnabled,
    required this.privacyLevel,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String language;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool notificationsEnabled;
  final ProfilePrivacyLevel privacyLevel;

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      language: json['language'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notificationsEnabled: json['notificationsEnabled'] as bool,
      privacyLevel: ProfilePrivacyLevel.fromJson(json['privacyLevel'] as String),
    );
  }
}
