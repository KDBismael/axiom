import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/badges/app_rank_progress_card.dart';
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
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
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
                          AnimatedOpacity(
                            opacity: _visible ? 1 : 0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: _CelebrationText(
                              periodComplete: periodComplete,
                              result: result,
                              quest: quest,
                              requiresProof: requiresProof,
                            ),
                          ),
                          const SizedBox(height: 26),
                          AnimatedOpacity(
                            opacity: _visible ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: _RankCard(
                              requiresProof: requiresProof,
                              evidenceStatus: result.evidence?.status,
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
      title = '${result.currentPeriodCount}/${result.targetPerPeriod}'
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
        pointsLine = Text(
          pending ? '+20 PTS · EN ATTENTE' : '',
          style: TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: 12,
            color: pending ? AppColors.outline : AppColors.volt,
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        child: AppRankProgressCard(rank: rank, pointsLine: pointsLine),
      );
    });
  }
}

/// The spark-burst + centered ember square, reproducing the mockup's
/// `ndPop`/`ndSpark` keyframes: the square pops in with an overshoot, while
/// a ring of small diamonds bursts outward and fades.
class _EmberBurst extends StatefulWidget {
  const _EmberBurst({required this.streakDays});

  final int streakDays;

  @override
  State<_EmberBurst> createState() => _EmberBurstState();
}

class _EmberBurstState extends State<_EmberBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _sparkColors = [
    AppColors.emberBright,
    AppColors.ember,
    AppColors.gold,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(12, (i) {
                  final angle = (2 * math.pi / 12) * i;
                  final delay = (i % 4) * 0.08;
                  final t = ((_controller.value - delay) / 0.5).clamp(0.0, 1.0);
                  final scale = t < 0.35
                      ? (t / 0.35) * 1.4
                      : 1.4 - ((t - 0.35) / 0.65) * 1.0;
                  final opacity = t <= 0 ? 0.0 : (1 - t).clamp(0.0, 1.0);
                  final distance = 70 + (i % 3) * 12;
                  return Transform.translate(
                    offset: Offset(
                      math.cos(angle) * distance,
                      math.sin(angle) * distance,
                    ),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale.clamp(0.0, 1.6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _sparkColors[i % _sparkColors.length],
                            borderRadius: BorderRadius.circular(2),
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
              return Transform.scale(scale: scale, child: child);
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
                borderRadius: AppRadii.structuralRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ember.withValues(alpha: 0.55),
                    blurRadius: 60,
                  ),
                ],
              ),
              alignment: Alignment.center,
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
        ],
      ),
    );
  }
}
