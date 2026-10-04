import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/avatar_colors.dart';
import '../../../core/widgets/badges/app_rank_badge.dart';
import '../../../core/widgets/badges/app_trophy_grid.dart';
import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../rank/controllers/rank_controller.dart';
import '../../rank/models/rank_summary.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/models/ally_request.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import '../widgets/authenticated_avatar_image.dart';
import '../widgets/invite_friends_sheet.dart';
import '../widgets/manage_allies_sheet.dart';
import '../widgets/personal_info_sheet.dart';
import '../widgets/profile_editable_fields.dart';

/// "Profile" tab — rank identity, quest stats, trophies, ally requests, and
/// account settings. Editing name/email/phone/photo lives in its own
/// "Informations personnelles" screen, reached from the settings row below.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Future<void> _logout() async {
    await Get.find<AuthController>().logout();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _handleSave(ProfileController controller) async {
    await controller.save();
    if (!mounted || controller.errorMessage.value != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Modifications enregistrées.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Column(
      children: [
        SizedBox(height: 64),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value && controller.profile.value == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.volt),
              );
            }
            final hasUnsavedChanges = controller.hasUnsavedChanges;
            return Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, hasUnsavedChanges ? 76 : 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROFIL',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 16),
                        const _RankHeroCard(),
                        const SizedBox(height: 18),
                        const _ProfileStatsRow(),
                        const SizedBox(height: 32),
                        Text(
                          'TROPHÉES',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 16),
                        Builder(
                          builder: (context) {
                            final rank = Get.find<RankController>();
                            return Obx(() {
                              final trophies = rank.trophies.toList();
                              return AppTrophyGrid(trophies: trophies);
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        Builder(
                          builder: (context) {
                            final allies = Get.find<AlliesController>();
                            return Obx(() {
                              final incoming = allies.incomingRequests;
                              if (incoming.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DEMANDES D'ALLIÉS",
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  for (final request in incoming) ...[
                                    _AllyRequestRow(
                                      request: request,
                                      onAccept: () =>
                                          allies.respondToRequest(request.id, accept: true),
                                      onDecline: () =>
                                          allies.respondToRequest(request.id, accept: false),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  const SizedBox(height: 22),
                                ],
                              );
                            });
                          },
                        ),
                        _ValidationsLinkCard(
                          onTap: () => Get.toNamed(AppRoutes.allyValidations),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'PARAMÈTRES',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: AppRadii.structuralRadius,
                            border: Border.all(color: AppColors.outlineVariant15),
                          ),
                          child: Column(
                            children: [
                              Obx(
                                () => _PersonalInfoRow(
                                  profile: controller.profile.value,
                                  onTap: () => showAppBottomSheet(
                                    context,
                                    builder: (_) => const PersonalInfoSheet(),
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: AppColors.outlineVariant15),
                              _InviteFriendsRow(
                                onTap: () => showAppBottomSheet(
                                  context,
                                  builder: (_) => const InviteFriendsSheet(),
                                ),
                              ),
                              Divider(height: 1, color: AppColors.outlineVariant15),
                              _ManageAlliesRow(
                                onTap: () => showAppBottomSheet(
                                  context,
                                  builder: (_) => const ManageAlliesSheet(),
                                ),
                              ),
                              // Langue / Confidentialité — disabled for now, may come back later.
                              // Divider(height: 1, color: AppColors.outlineVariant15),
                              // Obx(
                              //   () => _SegmentedSettingRow(
                              //     label: 'Langue',
                              //     options: const {'fr': 'Français', 'en': 'English'},
                              //     current: controller.language.value,
                              //     onSelected: (value) => controller.language.value = value,
                              //   ),
                              // ),
                              // Divider(height: 1, color: AppColors.outlineVariant15),
                              // Obx(
                              //   () => _SegmentedSettingRow(
                              //     label: 'Confidentialité',
                              //     options: const {
                              //       'standard': 'Standard',
                              //       'private': 'Privé',
                              //     },
                              //     current: controller.privacyLevel.value.toJson(),
                              //     onSelected: (value) => controller.privacyLevel.value =
                              //         ProfilePrivacyLevel.fromJson(value),
                              //   ),
                              // ),
                              Divider(height: 1, color: AppColors.outlineVariant15),
                              Obx(
                                () => _NotificationsToggleRow(
                                  value: controller.notificationsEnabled.value,
                                  onChanged: (value) =>
                                      controller.notificationsEnabled.value = value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(() {
                          final error = controller.errorMessage.value;
                          if (error == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              error,
                              style: AppTypography.labelMd.copyWith(color: AppColors.error),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorSoft,
                              side: const BorderSide(color: AppColors.errorBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadii.interactiveRadius,
                              ),
                            ),
                            child: const Text(
                              'Se déconnecter',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasUnsavedChanges)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ProfileSaveBar(
                      saving: controller.isSaving.value,
                      onSave: () => _handleSave(controller),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// Langue / Confidentialité are disabled for now (see the settings Column
// above) — kept here, commented out, in case they come back later.
/*
/// A labeled setting whose value is picked inline via a 2-option segmented
/// pill track, rather than opening a bottom sheet (Langue/Confidentialité).
class _SegmentedSettingRow extends StatelessWidget {
  const _SegmentedSettingRow({
    required this.label,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  final String label;
  final Map<String, String> options;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in options.entries)
                  GestureDetector(
                    onTap: () => onSelected(entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: entry.key == current ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: entry.key == current ? AppColors.onPrimary : AppColors.outline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/

class _NotificationsToggleRow extends StatelessWidget {
  const _NotificationsToggleRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text('Notifications', style: TextStyle(fontSize: 14, color: AppColors.outline)),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.volt),
        ],
      ),
    );
  }
}

/// "Informations personnelles" entry point — opens the [PersonalInfoSheet]
/// for name/email/phone. Photo upload is disabled for now, so the avatar
/// is always the initials chip.
class _PersonalInfoRow extends StatelessWidget {
  const _PersonalInfoRow({required this.profile, required this.onTap});

  final Profile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstName = profile?.firstName ?? '';
    final lastName = profile?.lastName ?? '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AuthenticatedAvatarImage(
              avatarUrl: null,
              size: 40,
              borderRadius: BorderRadius.circular(12),
              initials: initialsFor(firstName, lastName),
              backgroundColor: AppColors.volt,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Informations personnelles',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile == null ? '' : '$firstName $lastName · ${profile!.email}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.outline),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InviteFriendsRow extends StatelessWidget {
  const _InviteFriendsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2610),
                border: Border.all(color: const Color(0xFF2F3F14)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '+',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.volt,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inviter des amis',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '+50 pts de rang par ami inscrit',
                    style: TextStyle(fontSize: 12.5, color: AppColors.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PARTAGER',
              style: AppTypography.labelMd.copyWith(color: AppColors.volt, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Gérer mes alliés" entry point — separate from "Inviter des amis": this
/// opens [ManageAlliesSheet], where the only action is removing an ally.
class _ManageAlliesRow extends StatelessWidget {
  const _ManageAlliesRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final allies = Get.find<AlliesController>();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.group_outlined, color: AppColors.outline, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Gérer mes alliés',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.primary),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final count = allies.allies.length;
                    return Text(
                      count == 0 ? 'Aucun allié' : '$count allié${count > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.outline),
                    );
                  }),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Plain nav entry to the validations screen (pending + history) — the
/// "you have proofs to judge" reminder itself lives on the dashboard
/// instead ([HomeView]'s `_PendingValidationsBanner`), so this stays a
/// low-key link rather than duplicating that card here.
class _ValidationsLinkCard extends StatelessWidget {
  const _ValidationsLinkCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Validations d'alliés",
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: AppColors.outline, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllyRequestRow extends StatelessWidget {
  const _AllyRequestRow({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  final AllyRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final firstName = request.otherUser.firstName;
    final lastName = request.otherUser.lastName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant15),
      ),
      child: Row(
        children: [
          AuthenticatedAvatarImage(
            // Photo upload is disabled for now — always show initials.
            avatarUrl: null,
            size: 40,
            borderRadius: BorderRadius.circular(12),
            initials: initialsFor(firstName, lastName),
            backgroundColor: avatarColorForId(request.otherUser.id),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$firstName $lastName',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.primary),
            ),
          ),
          InkWell(
            onTap: onDecline,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBright),
              ),
              child: const Icon(Icons.close, color: AppColors.outline, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: AppPressable(
              color: AppColors.volt,
              shadowColor: AppColors.voltShadow,
              shadowThickness: 3,
              onTap: onAccept,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Center(
                  child: Text(
                    'Accepter',
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.onPrimary,
                    ),
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

class _RankHeroCard extends StatelessWidget {
  const _RankHeroCard();

  @override
  Widget build(BuildContext context) {
    final rankController = Get.find<RankController>();
    final profileController = Get.find<ProfileController>();
    return Obx(() {
      final rank = rankController.rank.value;
      if (rank == null) return const SizedBox.shrink();
      final profile = profileController.profile.value;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.rankCardGoldBg, AppColors.surfaceContainerLow],
            stops: [0, 0.65],
          ),
          borderRadius: AppRadii.sheetRadius,
          border: Border.all(color: AppColors.rankCardGoldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppRankBadge(
                  tier: rank.tier,
                  subLevel: rank.subLevel,
                  width: 72,
                  height: 80,
                  fontSize: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile == null ? '' : '${profile.firstName} ${profile.lastName}',
                        style: const TextStyle(
                          fontFamily: 'Unbounded',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 1.15,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RANG ${rank.rankLabel.toUpperCase()} · '
                        '${rank.isMaxRank ? "MAXIMUM" : "${rank.pointsToNextSubLevel} PTS VERS ${rank.nextMilestoneLabel.toUpperCase()}"}',
                        style: const TextStyle(
                          fontFamily: 'Geist Mono',
                          fontSize: 12,
                          letterSpacing: 0.12 * 12,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var i = 0; i < rankTiers.length; i++)
                  Expanded(
                    child: Opacity(
                      opacity: i <= rank.tierIndex ? 1 : 0.35,
                      child: Column(
                        children: [
                          AppRankBadge(
                            tier: rankTiers[i],
                            subLevel: '',
                            width: 30,
                            height: 34,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rankTiers[i],
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFFD8D8DE)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow();

  @override
  Widget build(BuildContext context) {
    final questController = Get.find<QuestListController>();
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _StatTile(
              value: '${questController.activeQuests.length}',
              label: 'quêtes actives',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              value: questController.totalStakeAmount.toStringAsFixed(0),
              label: 'XOF engagés',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              value: questController.riskLevel,
              label: 'niveau de risque',
              valueColor: AppColors.emberLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    this.valueColor = AppColors.primary,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.structuralRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.outline)),
        ],
      ),
    );
  }
}
