/// `GET /allies/leaderboard` item — self + mutual allies, sorted by
/// lifetime points desc.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.totalPoints,
    required this.tier,
    required this.subLevel,
    required this.rankLabel,
    required this.currentStreakDays,
    required this.isMe,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int totalPoints;
  final String tier;
  final String subLevel;
  final String rankLabel;
  final int currentStreakDays;
  final bool isMe;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: json['totalPoints'] as int,
      tier: json['tier'] as String,
      subLevel: json['subLevel'] as String,
      rankLabel: json['rankLabel'] as String,
      currentStreakDays: json['currentStreakDays'] as int,
      isMe: json['isMe'] as bool,
    );
  }
}
