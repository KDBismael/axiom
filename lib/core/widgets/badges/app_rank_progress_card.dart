import 'package:flutter/material.dart';
import '../../../features/rank/models/rank_summary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import 'app_rank_badge.dart';

/// The gold "RANG" card: badge and progress toward the next milestone.
/// Shows earned points and the target; it does not show a competing
/// "points remaining" number. Used on Home and the Celebration screen.
class AppRankProgressCard extends StatelessWidget {
  const AppRankProgressCard({
    super.key,
    required this.rank,
    this.onTap,
    this.pointsLine,
  });

  final RankSummary rank;
  final VoidCallback? onTap;

  /// Optional trailing "+20 PTS" (or provisional) line shown next to the
  /// rank label, as on the Celebration screen. Omitted on Home.
  final Widget? pointsLine;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.rankCardGoldBg, AppColors.surfaceContainerLow],
            stops: [0, 0.7],
          ),
          borderRadius: AppRadii.structuralRadius,
          border: Border.all(color: AppColors.rankCardGoldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppRankBadge(tier: rank.tier, subLevel: rank.subLevel),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RANG',
                        style: AppTypography.labelMd.copyWith(
                          fontSize: 10.5,
                          color: const Color(0xFFC9A94E),
                        ),
                      ),
                      Text(
                        rank.rankLabel.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pointsLine != null) pointsLine!,
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rank.nextMilestoneRatio,
                minHeight: 6,
                backgroundColor: AppColors.rankTrackGold,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TES POINTS : ${rank.totalPoints} pts',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.rankCaptionGold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              rank.isMaxRank
                  ? 'Rang maximum atteint'
                  : 'Prochain palier : ${rank.nextMilestoneLabel} à ${rank.nextMilestonePoints} pts',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.rankCaptionGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
