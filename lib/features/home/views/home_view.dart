import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_ally_invitation_summary.dart';
import '../../quests/models/quest_group_invitation_summary.dart';
import '../../quests/models/quest_pause_request_summary.dart';
import '../../quests/widgets/quest_summary_card.dart';

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
        // Translucent header bar, painted first (behind) so the scroll
        // content below passes in front of / over it visually.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlassChrome(
            safeAreaTop: true,
            child: SizedBox(height: _headerHeight),
          ),
        ),
        // Full-bleed scroll content, painted second (in front of the bar) —
        // it visibly scrolls up and over the header bar.
        Positioned.fill(
          child: Obx(() {
            if (controller.isLoading.value && controller.quests.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 1),
              );
            }
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                topInset + _headerHeight,
                24,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Greeting(),
                  const SizedBox(height: 24),
                  _StakeAndRiskCard(controller: controller),
                  const SizedBox(height: 32),
                  if (controller.pendingAllyInvitations.isNotEmpty ||
                      controller.pendingGroupInvitations.isNotEmpty ||
                      controller.pendingPauseRequests.isNotEmpty) ...[
                    Text(
                      'INVITATIONS EN ATTENTE',
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final invitation
                        in controller.pendingAllyInvitations) ...[
                      _PendingAllyInvitationCard(invitation: invitation),
                      const SizedBox(height: 16),
                    ],
                    for (final invitation
                        in controller.pendingGroupInvitations) ...[
                      _PendingGroupInvitationCard(invitation: invitation),
                      const SizedBox(height: 16),
                    ],
                    for (final request in controller.pendingPauseRequests) ...[
                      _PendingPauseRequestCard(request: request),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 32),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'QUÊTES ACTIVES',
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${controller.activeQuests.length} EN COURS',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final quest in controller.activeQuests) ...[
                    QuestSummaryCard(quest: quest),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'CRÉER UNE QUÊTE',
                    onPressed: () => Get.toNamed(AppRoutes.questCreate),
                  ),
                ],
              ),
            );
          }),
        ),
        // Notification icon, painted last (always on top) so it stays
        // reachable regardless of what the scroll content is doing.
        Positioned(
          top: topInset,
          right: 24,
          child: Builder(
            builder: (context) {
              final notifications = Get.find<NotificationController>();
              return Obx(() {
                final unread = notifications.unreadCount;
                return InkWell(
                  onTap: () => Get.toNamed(AppRoutes.notifications),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: AppColors.primary,
                          ),
                          if (unread > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.volt,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
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

class _PendingAllyInvitationCard extends StatelessWidget {
  const _PendingAllyInvitationCard({required this.invitation});

  final QuestAllyInvitationSummary invitation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.questAllyInvitation,
        arguments: invitation.questId,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.volt.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVITATION EN TANT QU\'ALLIÉ',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invitation.questTitle,
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (invitation.inviterName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Invité par ${invitation.inviterName}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Get.toNamed(
                AppRoutes.questAllyInvitation,
                arguments: invitation.questId,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                foregroundColor: AppColors.volt,
                side: const BorderSide(color: AppColors.volt),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.interactiveRadius,
                ),
              ),
              child: Text(
                'RÉPONDRE',
                style: AppTypography.labelMd.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingGroupInvitationCard extends StatelessWidget {
  const _PendingGroupInvitationCard({required this.invitation});

  final QuestGroupInvitationSummary invitation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.questGroupInvitation,
        arguments: invitation.groupId,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.volt.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INVITATION À UNE QUÊTE COLLECTIVE',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invitation.groupTitle,
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (invitation.inviterName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Invité par ${invitation.inviterName}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => Get.toNamed(
                AppRoutes.questGroupInvitation,
                arguments: invitation.groupId,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                foregroundColor: AppColors.volt,
                side: const BorderSide(color: AppColors.volt),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.interactiveRadius,
                ),
              ),
              child: Text(
                'RÉPONDRE',
                style: AppTypography.labelMd.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingPauseRequestCard extends StatelessWidget {
  const _PendingPauseRequestCard({required this.request});

  final QuestPauseRequestSummary request;

  void _open() => Get.toNamed(
    AppRoutes.questPauseDecision,
    arguments: {'questId': request.questId, 'requestId': request.requestId},
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.interactiveRadius,
          border: Border.all(color: AppColors.volt.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DEMANDE DE PAUSE',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.questTitle,
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (request.requesterName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Demandée par ${request.requesterName}',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _open,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(64, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                foregroundColor: AppColors.volt,
                side: const BorderSide(color: AppColors.volt),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.interactiveRadius,
                ),
              ),
              child: Text(
                'RÉPONDRE',
                style: AppTypography.labelMd.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final user = auth.user.value;
      final firstName = user?.firstName.trim();
      final initials = (firstName != null && firstName.isNotEmpty)
          ? firstName.substring(0, 1).toUpperCase()
          : '?';
      return Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.volt, borderRadius: AppRadii.interactiveRadius),
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TABLEAU DE BORD',
                style: AppTypography.labelMd.copyWith(color: AppColors.outlineMuted),
              ),
              const SizedBox(height: 2),
              Text(
                firstName == null || firstName.isEmpty ? 'Salut !' : 'Salut, $firstName',
                style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontSize: 20),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _StakeAndRiskCard extends StatelessWidget {
  const _StakeAndRiskCard({required this.controller});

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
                  style: AppTypography.labelMd.copyWith(fontSize: 10.5, color: AppColors.outlineMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatXof(controller.totalStakeAmount),
                      style: AppTypography.headlineMd.copyWith(color: AppColors.primary, fontSize: 24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'XOF',
                      style: AppTypography.labelMd.copyWith(color: AppColors.outlineMuted, fontSize: 12),
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
                style: AppTypography.labelMd.copyWith(color: AppColors.emberLight, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
