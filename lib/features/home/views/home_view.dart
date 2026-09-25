import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/avatar_colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/badges/app_ally_leaderboard.dart';
import '../../../core/widgets/badges/app_rank_progress_card.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../../core/widgets/progress/segmented_progress.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../../quests/utils/quest_kind.dart';
import '../../rank/controllers/rank_controller.dart';
import '../../social/controllers/validations_controller.dart';

/// L'onglet "Tableau de bord" — rendu à l'intérieur du shell à navigation
/// persistante de l'app (voir `MainShellView`), il possède donc son propre
/// en-tête vitré mais pas de barre de navigation basse.
class HomeView extends GetView<QuestListController> {
  const HomeView({super.key});

  static const _headerHeight = 30.0;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlassChrome(
            safeAreaTop: true,
            child: SizedBox(height: _headerHeight),
          ),
        ),
        Positioned.fill(
          child: Obx(() {
            if (controller.isLoading.value && controller.quests.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 1),
              );
            }
            final rankController = Get.find<RankController>();
            final validations = Get.find<ValidationsController>();
            final pendingCount = validations.pendingValidations.length;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                topInset + _headerHeight,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Obx(() {
                          final rank = rankController.rank.value;
                          if (rank == null) return const SizedBox.shrink();
                          return AppRankProgressCard(
                            rank: rank,
                            onTap: () => Get.toNamed(AppRoutes.home),
                          );
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _StreakCard(controller: controller)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _TotalAtStakeCard(controller: controller),
                  const SizedBox(height: 16),
                  if (pendingCount > 0) ...[
                    _PendingValidationsBanner(count: pendingCount),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'QUÊTES ACTIVES',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outlineMuted,
                        ),
                      ),
                      Text(
                        '${controller.activeQuests.length} EN COURS',
                        style: AppTypography.labelMd.copyWith(
                          fontSize: 11,
                          color: AppColors.outlineFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final quest in controller.activeQuests) ...[
                    _HomeQuestCard(quest: quest),
                    const SizedBox(height: 16),
                  ],
                  _NewQuestButton(),
                  const SizedBox(height: 24),
                  Text(
                    'CLASSEMENT DES ALLIÉS',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outlineMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final entries = rankController.leaderboard;
                    if (entries.isEmpty) return const SizedBox.shrink();
                    return AppAllyLeaderboard(entries: entries);
                  }),
                ],
              ),
            );
          }),
        ),
        Positioned(
          top: topInset,
          right: 20,
          child: Builder(
            builder: (context) {
              final notifications = Get.find<NotificationController>();
              return Obx(() {
                final unread = notifications.unreadCount;
                return InkWell(
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: AppRadii.interactiveRadius,
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: AppColors.primary,
                        ),
                        if (unread > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.ember,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surfaceContainerLow,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final user = auth.user.value;
      final firstName = user?.firstName.trim() ?? '';
      final lastName = user?.lastName.trim() ?? '';
      return SizedBox(
        height: 52,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.home),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: AppRadii.interactiveRadius,
                ),
                child: Text(
                  initialsFor(firstName, lastName),
                  style: const TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TABLEAU DE BORD',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outlineMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstName.isEmpty ? 'Salut !' : 'Salut, $firstName',
                    style: const TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.controller});

  final QuestListController controller;

  @override
  Widget build(BuildContext context) {
    final bestStreak = controller.activeQuests.fold<int>(
      0,
      (best, q) => q.streakDays > best ? q.streakDays : best,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.streakCardEmberBg, AppColors.surfaceContainerLow],
          stops: [0, 0.7],
        ),
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.streakCardEmberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SÉRIE',
            style: AppTypography.labelMd.copyWith(
              fontSize: 10.5,
              color: AppColors.emberLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.emberBright, AppColors.emberDeep],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$bestStreak',
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                  height: 1,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'jours sans rupture',
            style: TextStyle(fontSize: 12, color: AppColors.streakCaptionEmber),
          ),
        ],
      ),
    );
  }
}

class _TotalAtStakeCard extends StatelessWidget {
  const _TotalAtStakeCard({required this.controller});

  final QuestListController controller;

  static const _riskBarsByLevel = {'FAIBLE': 1, 'MODÉRÉ': 2, 'ÉLEVÉ': 3};

  @override
  Widget build(BuildContext context) {
    final filledBars = _riskBarsByLevel[controller.riskLevel] ?? 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL EN JEU',
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 10.5,
                    color: AppColors.outlineMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      controller.totalStakeAmount.toStringAsFixed(0),
                      style: const TextStyle(
                        fontFamily: 'Unbounded',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'XOF',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outlineMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(3, (i) {
                  final filled = i < filledBars;
                  return Container(
                    width: 8,
                    height: 8.0 + i * 5,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: filled ? AppColors.ember : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                controller.riskLevel,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.emberLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingValidationsBanner extends StatelessWidget {
  const _PendingValidationsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.allyValidations),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF17142A),
          borderRadius: AppRadii.sheetRadius,
          border: Border.all(color: const Color(0xFF3B2F5F)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preuves à juger',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.primary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tes alliés attendent ton verdict',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFFA79EE0)),
                  ),
                ],
              ),
            ),
            const Text('→', style: TextStyle(color: Color(0xFFA79EE0), fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _NewQuestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton(
        onPressed: () => Get.toNamed(AppRoutes.questCreate),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.outlineVariantStrong, width: 1.5, style: BorderStyle.solid),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
        ),
        child: Text(
          '+ NOUVELLE QUÊTE',
          style: TextStyle(
            fontFamily: 'Unbounded',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.06 * 13,
            color: AppColors.volt,
          ),
        ),
      ),
    );
  }
}

class _HomeQuestCard extends StatelessWidget {
  const _HomeQuestCard({required this.quest});

  final QuestModel quest;

  static const _kindColors = {
    QuestKind.solo: AppColors.outlineMuted,
    QuestKind.collective: AppColors.violet,
    QuestKind.offerte: AppColors.waveCyan,
  };

  @override
  Widget build(BuildContext context) {
    final myId = Get.find<AuthController>().user.value?.id;
    final kind = questKindFor(quest, myId);
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.questDetail, arguments: quest.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.structuralRadius,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questKindLabels[kind]!,
                        style: AppTypography.labelMd.copyWith(
                          fontSize: 10.5,
                          color: _kindColors[kind],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        quest.title,
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          height: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _TrailingAction(quest: quest),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedProgress(ratio: quest.progress),
            const SizedBox(height: 14),
            Row(
              children: [
                Transform.rotate(
                  angle: 0.7853981633974483,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.ember,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${quest.streakDays}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  quest.frequency == QuestFrequency.daily
                      ? (quest.streakDays > 1 ? 'jours' : 'jour')
                      : (quest.streakDays > 1 ? 'semaines' : 'semaine'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.outline),
                ),
                const SizedBox(width: 14),
                Text(
                  '${(quest.progress * 100).round()}%',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.outline),
                ),
                const Spacer(),
                if (quest.hasStake && quest.stakeAmountXof != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2610),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      formatXof(quest.stakeAmountXof!),
                      style: const TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: 11.5,
                        color: AppColors.volt,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({required this.quest});

  final QuestModel quest;

  @override
  Widget build(BuildContext context) {
    if (quest.isPaused) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'EN PAUSE',
          style: AppTypography.labelMd.copyWith(
            fontSize: 10.5,
            color: AppColors.outlineMuted,
          ),
        ),
      );
    }
    if (quest.isPendingPayment) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.volt.withValues(alpha: 0.4)),
        ),
        child: Text(
          'PAIEMENT',
          style: AppTypography.labelMd.copyWith(fontSize: 10.5, color: AppColors.volt),
        ),
      );
    }
    if (quest.isPendingOwnerAcceptance) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          'EN ATTENTE',
          style: AppTypography.labelMd.copyWith(fontSize: 10.5, color: AppColors.outlineMuted),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: AppPressable(
        color: AppColors.volt,
        shadowColor: AppColors.voltShadow,
        shadowThickness: 3,
        onTap: () => Get.toNamed(AppRoutes.questValidation, arguments: quest.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              'VALIDER',
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.06 * 11,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
