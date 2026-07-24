import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_ally_invitation_summary.dart';
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
            if (controller.isLoading.value) {
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
                  Text(
                    'STATUT ACTUEL',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TABLEAU DE BORD',
                    style: AppTypography.displayLg.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _StatsRow(controller: controller),
                  const SizedBox(height: 48),
                  if (controller.pendingAllyInvitations.isNotEmpty) ...[
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
                                  color: AppColors.emerald,
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
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
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
                foregroundColor: AppColors.emerald,
                side: const BorderSide(color: AppColors.emerald),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final QuestListController controller;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 7,
            child: _StatCard(
              background: AppColors.surfaceContainerLow,
              labelColor: AppColors.outline,
              valueColor: AppColors.primary,
              label: 'ENJEUX TOTAUX',
              value: formatXof(controller.totalStakeAmount),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: _StatCard(
              background: AppColors.primary,
              labelColor: Colors.black,
              valueColor: Colors.black,
              label: 'NIVEAU DE RISQUE',
              value: controller.riskLevel,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.background,
    required this.labelColor,
    required this.valueColor,
    required this.label,
    required this.value,
  });

  final Color background;
  final Color labelColor;
  final Color valueColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.interactiveRadius,
        border: background == AppColors.surfaceContainerLow
            ? Border.all(color: AppColors.outlineVariant15)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMd.copyWith(color: labelColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headlineMd.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
