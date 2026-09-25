const List<String> rankTiers = ['Bronze', 'Argent', 'Or', 'Platine', 'Obsidienne'];
const List<String> rankSubLevels = ['I', 'II', 'III'];
const int pointsPerSubLevel = 500;

/// `GET /me/rank` response — the lifetime points ledger summed into a
/// tier/sub-level position. Always computed server-side from
/// `SUM(PointsEntry.amount)`; never cached client-side beyond this snapshot.
class RankSummary {
  const RankSummary({
    required this.totalPoints,
    required this.tier,
    required this.tierIndex,
    required this.subLevel,
    required this.subLevelIndex,
    required this.rankLabel,
    required this.pointsIntoTier,
    required this.pointsIntoSubLevel,
    required this.pointsToNextSubLevel,
    required this.pointsToNextTier,
    required this.isMaxRank,
  });

  final int totalPoints;
  final String tier;
  final int tierIndex;
  final String subLevel;
  final int subLevelIndex;
  final String rankLabel;
  final int pointsIntoTier;
  final int pointsIntoSubLevel;
  final int pointsToNextSubLevel;
  final int pointsToNextTier;
  final bool isMaxRank;

  /// The name shown as "vers `<name>`" — the next tier, or (once inside the
  /// final tier but not yet maxed) the next sub-level within it.
  String get nextMilestoneLabel {
    if (isMaxRank) return 'rang maximum';
    if (tierIndex < rankTiers.length - 1) return rankTiers[tierIndex + 1];
    return '$tier ${rankSubLevels[subLevelIndex + 1]}';
  }

  double get subLevelRatio => pointsIntoSubLevel / pointsPerSubLevel;

  factory RankSummary.fromJson(Map<String, dynamic> json) {
    return RankSummary(
      totalPoints: json['totalPoints'] as int,
      tier: json['tier'] as String,
      tierIndex: json['tierIndex'] as int,
      subLevel: json['subLevel'] as String,
      subLevelIndex: json['subLevelIndex'] as int,
      rankLabel: json['rankLabel'] as String,
      pointsIntoTier: json['pointsIntoTier'] as int,
      pointsIntoSubLevel: json['pointsIntoSubLevel'] as int,
      pointsToNextSubLevel: json['pointsToNextSubLevel'] as int,
      pointsToNextTier: json['pointsToNextTier'] as int,
      isMaxRank: json['isMaxRank'] as bool,
    );
  }
}
