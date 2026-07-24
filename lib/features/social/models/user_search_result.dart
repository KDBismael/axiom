/// A user-search hit — `GET /users/search?q=`.
class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
