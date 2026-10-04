import 'package:axiom/features/rank/models/rank_summary.dart';
import 'package:flutter_test/flutter_test.dart';

RankSummary rankAt({
  required int total,
  required int tierIndex,
  required int subLevelIndex,
  required int remaining,
}) => RankSummary(
  totalPoints: total,
  tier: rankTiers[tierIndex],
  tierIndex: tierIndex,
  subLevel: rankSubLevels[subLevelIndex],
  subLevelIndex: subLevelIndex,
  rankLabel: '${rankTiers[tierIndex]} ${rankSubLevels[subLevelIndex]}',
  pointsIntoTier: total % 1500,
  pointsIntoSubLevel: total % pointsPerSubLevel,
  pointsToNextSubLevel: remaining,
  pointsToNextTier: 1500 - total % 1500,
  isMaxRank: false,
);

void main() {
  test('585 total points need 415 more for Bronze III, not Argent', () {
    final rank = rankAt(
      total: 585,
      tierIndex: 0,
      subLevelIndex: 1,
      remaining: 415,
    );

    expect(rank.nextMilestoneLabel, 'Bronze III');
    expect(rank.nextMilestonePoints, 1000);
    expect(rank.nextMilestoneRatio, 0.585);
  });

  test('Bronze III progresses to Argent I at 1500 points', () {
    final rank = rankAt(
      total: 1100,
      tierIndex: 0,
      subLevelIndex: 2,
      remaining: 400,
    );

    expect(rank.nextMilestoneLabel, 'Argent I');
    expect(rank.nextMilestonePoints, 1500);
    expect(rank.nextMilestoneRatio, closeTo(1100 / 1500, 0.0001));
  });

  test('Obsidienne III has no further milestone', () {
    final rank = RankSummary(
      totalPoints: 7500,
      tier: 'Obsidienne',
      tierIndex: 4,
      subLevel: 'III',
      subLevelIndex: 2,
      rankLabel: 'Obsidienne III',
      pointsIntoTier: 1500,
      pointsIntoSubLevel: 500,
      pointsToNextSubLevel: 0,
      pointsToNextTier: 0,
      isMaxRank: true,
    );

    expect(rank.nextMilestoneLabel, 'rang maximum');
    expect(rank.nextMilestonePoints, isNull);
    expect(rank.nextMilestoneRatio, 1);
  });
}
