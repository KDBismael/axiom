import 'package:flutter/material.dart';
import '../../../features/rank/models/leaderboard_entry.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../utils/avatar_colors.dart';

const _rankPositionColors = [
  AppColors.gold, // #1
  Color(0xFFD8D8DE), // #2
  AppColors.bronzeLight, // #3
];

/// Ranked list of self + mutual allies by lifetime points — "CLASSEMENT DES
/// ALLIÉS" on the Home dashboard.
class AppAllyLeaderboard extends StatelessWidget {
  const AppAllyLeaderboard({super.key, required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _LeaderboardRow(position: i + 1, entry: entries[i]),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.position, required this.entry});

  final int position;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final positionColor = position <= 3
        ? _rankPositionColors[position - 1]
        : AppColors.outlineMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: entry.isMe ? AppColors.voltTint(0.05) : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$position',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: positionColor,
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: avatarColorForId(entry.userId),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              initialsFor(entry.firstName, entry.lastName),
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.isMe ? 'Toi' : '${entry.firstName} ${entry.lastName}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              Transform.rotate(
                angle: 0.7853981633974483,
                child: Container(width: 7, height: 7, color: AppColors.ember),
              ),
              const SizedBox(width: 6),
              Text(
                '${entry.currentStreakDays}',
                style: AppTypography.bodyMd.copyWith(
                  fontSize: 12,
                  color: AppColors.emberLight,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${entry.totalPoints} pts',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Geist Mono',
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
