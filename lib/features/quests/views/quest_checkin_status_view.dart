import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../rank/controllers/rank_controller.dart';
import '../controllers/quest_list_controller.dart';
import '../models/check_in_model.dart';
import '../models/quest_model.dart';

/// The "Celebration" screen — shown immediately after every check-in
/// submission (mockup's `isDone` state). Points are never awarded by the
/// backend at submission time (only later, on approval — see
/// `GamificationService`), so this screen shows the check-in's own +20 as
/// provisional/pending for a proof-required quest, and no points line at
/// all for a no-proof quest.
class QuestCheckinStatusView extends StatefulWidget {
  const QuestCheckinStatusView({super.key});

  @override
  State<QuestCheckinStatusView> createState() => _QuestCheckinStatusViewState();
}

class _QuestCheckinStatusViewState extends State<QuestCheckinStatusView> {
  bool _textVisible = false;
  bool _rankVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _textVisible = true);
    });
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _rankVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final questId = args['questId'] as String;
    final requiresProof = args['requiresProof'] as bool;
    final result = args['result'] as CheckInResult;

    final questController = Get.find<QuestListController>();
    final quest = questController.findById(questId);
    final periodComplete = result.currentPeriodCount >= result.targetPerPeriod;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.36),
            radius: 0.9,
            colors: [Color(0xFF3A1A08), AppColors.surface],
            stops: [0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _EmberBurst(streakDays: result.streakDays),
                          const SizedBox(height: 26),
                          AnimatedSlide(
                            offset: _textVisible
                                ? Offset.zero
                                : const Offset(0, 0.12),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: _textVisible ? 1 : 0,
                              duration: const Duration(milliseconds: 400),
                              child: _CelebrationText(
                                periodComplete: periodComplete,
                                result: result,
                                quest: quest,
                                requiresProof: requiresProof,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          AnimatedSlide(
                            offset: _rankVisible
                                ? Offset.zero
                                : const Offset(0, 0.12),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: _rankVisible ? 1 : 0,
                              duration: const Duration(milliseconds: 500),
                              child: _RankCard(
                                requiresProof: requiresProof,
                                evidenceStatus: result.evidence?.status,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppButton(
                  label: 'CONTINUER',
                  onPressed: () => Get.offAllNamed(AppRoutes.home),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationText extends StatelessWidget {
  const _CelebrationText({
    required this.periodComplete,
    required this.result,
    required this.quest,
    required this.requiresProof,
  });

  final bool periodComplete;
  final CheckInResult result;
  final QuestModel? quest;
  final bool requiresProof;

  @override
  Widget build(BuildContext context) {
    final frequency = quest?.frequency ?? QuestFrequency.daily;
    final String eyebrow;
    final String title;
    if (periodComplete) {
      eyebrow = 'SÉRIE PROLONGÉE · +1';
      title = 'Combo ×${result.streakDays}';
    } else {
      eyebrow = 'POINTAGE ENREGISTRÉ';
      title =
          '${result.currentPeriodCount}/${result.targetPerPeriod}'
          ' ${frequency == QuestFrequency.daily ? "aujourd'hui" : 'cette semaine'}';
    }

    final String message;
    if (!requiresProof) {
      message = 'Check-in enregistré. Continue comme ça.';
    } else if (result.evidence?.status == EvidenceStatus.approved) {
      message = 'Preuve approuvée automatiquement.';
    } else {
      final validators = (quest?.allies ?? const [])
          .where((a) => a.status == QuestAllyStatus.accepted)
          .map((a) => a.firstName)
          .where((name) => name.isNotEmpty)
          .toList();
      message = validators.isEmpty
          ? 'Preuve envoyée. Tes alliés vont la juger.'
          : 'Preuve envoyée. ${validators.join(' ou ')} va la juger.';
    }

    return Column(
      children: [
        Text(
          eyebrow,
          style: AppTypography.labelMd.copyWith(
            fontSize: 12,
            letterSpacing: 0.16 * 12,
            color: AppColors.emberLight,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            height: 1.1,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.outline,
            ),
          ),
        ),
      ],
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.requiresProof, required this.evidenceStatus});

  final bool requiresProof;
  final EvidenceStatus? evidenceStatus;

  @override
  Widget build(BuildContext context) {
    final rankController = Get.find<RankController>();
    return Obx(() {
      final rank = rankController.rank.value;
      if (rank == null) return const SizedBox.shrink();

      Widget? pointsLine;
      if (requiresProof) {
        final pending = evidenceStatus != EvidenceStatus.rejected;
        if (pending) {
          pointsLine = const Text(
            '+20 PTS · EN ATTENTE',
            style: TextStyle(
              fontFamily: 'Geist Mono',
              fontSize: 11,
              color: AppColors.outline,
            ),
          );
        }
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xD9141417),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3A3118)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rank.rankLabel.toUpperCase(),
                    style: AppTypography.labelMd.copyWith(
                      fontSize: 13,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                if (pointsLine != null) pointsLine,
              ],
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rank.nextMilestoneRatio),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF2C2616),
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              rank.isMaxRank
                  ? '${rank.totalPoints} pts acquis · rang maximum'
                  : '${rank.totalPoints} pts acquis · ${rank.nextMilestoneLabel} à ${rank.nextMilestonePoints} pts',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: Color(0xFFB8A873),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// The 16 staggered diamonds and the central streak emblem from the
/// celebration reference.
class _EmberBurst extends StatefulWidget {
  const _EmberBurst({required this.streakDays});

  final int streakDays;

  @override
  State<_EmberBurst> createState() => _EmberBurstState();
}

class _EmberBurstState extends State<_EmberBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _sparkColors = [
    AppColors.ember,
    Color(0xFFFFD166),
    AppColors.volt,
  ];

  static const _sparkPositions = [
    Offset(203, 115),
    Offset(212.931, 155.564),
    Offset(202.681, 202.681),
    Offset(148.676, 196.301),
    Offset(115, 221),
    Offset(67.5473, 229.561),
    Offset(52.7746, 177.225),
    Offset(17.0688, 155.564),
    Offset(-9, 115),
    Offset(33.6986, 81.3239),
    Offset(40.0467, 40.0467),
    Offset(67.5473, 0.438938),
    Offset(115, 27),
    Offset(155.564, 17.0688),
    Offset(202.681, 27.3188),
    Offset(196.301, 81.3239),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: List.generate(_sparkPositions.length, (i) {
                  final size = i.isEven ? 12.0 : 8.0;
                  final delayMs = 250 + (i % 4) * 80;
                  final t = ((_controller.value * 1600 - delayMs) / 1100).clamp(
                    0.0,
                    1.0,
                  );
                  final opacity = t < 0.22 ? t / 0.22 : (1 - t) / 0.78;
                  final scale = t < 0.3
                      ? 0.4 + t / 0.3 * 0.9
                      : 1.3 - (t - 0.3) / 0.7 * 0.55;
                  final center =
                      _sparkPositions[i] + Offset(size / 2, size / 2);
                  final direction = center - const Offset(120, 120);
                  final length = direction.distance;
                  final travel = length == 0
                      ? Offset.zero
                      : direction / length * (-14 + 36 * t);
                  return Positioned(
                    left: _sparkPositions[i].dx,
                    top: _sparkPositions[i].dy,
                    child: Transform.translate(
                      offset: travel,
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale,
                          child: Transform.rotate(
                            angle: math.pi / 4,
                            child: Container(
                              key: Key('celebration-spark-$i'),
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: _sparkColors[i % _sparkColors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.3, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Transform.rotate(angle: math.pi / 4, child: child),
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD166),
                    AppColors.ember,
                    Color(0xFFE0401A),
                  ],
                  stops: [0, 0.55, 1],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ember.withValues(alpha: 0.55),
                    blurRadius: 60,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Text(
                  '${widget.streakDays}',
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w800,
                    fontSize: 44,
                    color: Color(0xFF1A0A02),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
