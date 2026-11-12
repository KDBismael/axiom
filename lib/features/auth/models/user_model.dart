class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.avatarUrl,
    this.onboardingCompletedAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Null until the first-run guided tour is finished or skipped.
  final DateTime? onboardingCompletedAt;

  User copyWith({DateTime? onboardingCompletedAt}) => User(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    role: role,
    createdAt: createdAt,
    updatedAt: updatedAt,
    phone: phone,
    avatarUrl: avatarUrl,
    onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
  );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      onboardingCompletedAt: json['onboardingCompletedAt'] == null
          ? null
          : DateTime.parse(json['onboardingCompletedAt'] as String),
    );
  }
}
