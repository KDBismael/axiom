import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/badges/app_rank_badge.dart';
import '../../../core/widgets/badges/app_trophy_grid.dart';
import '../../../core/widgets/sheets/app_bottom_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../rank/controllers/rank_controller.dart';
import '../../rank/models/rank_summary.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/controllers/validations_controller.dart';
import '../../social/models/ally_request.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import '../widgets/authenticated_avatar_image.dart';
import '../widgets/invite_friends_sheet.dart';
import '../widgets/phone_input_field.dart';

/// "Profile" tab — identity/security settings plus real quest stats.
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          SizedBox(height: 64),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.profile.value == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.volt),
                );
              }
              final hasUnsavedChanges = controller.hasUnsavedChanges;
              return Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        hasUnsavedChanges ? 76 : 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROFIL',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _RankHeroCard(),
                          const SizedBox(height: 18),
                          const _ProfileStatsRow(),
                          const SizedBox(height: 32),
                          Text(
                            'TROPHÉES',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final rank = Get.find<RankController>();
                              return Obx(
                                () => AppTrophyGrid(trophies: rank.trophies),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: controller.pickAndUploadAvatar,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AuthenticatedAvatarImage(
                                        avatarUrl:
                                            controller.profile.value?.avatarUrl,
                                        size: 112,
                                      ),
                                      Positioned(
                                        bottom: -8,
                                        right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: AppColors.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Obx(
                                  () => Text(
                                    controller.profile.value == null
                                        ? ''
                                        : '${controller.profile.value!.firstName} '
                                              '${controller.profile.value!.lastName}',
                                    style: AppTypography.displayLg.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: _ProfileField(
                                  label: 'PRÉNOM',
                                  controller: controller.firstNameController,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _ProfileField(
                                  label: 'NOM',
                                  controller: controller.lastNameController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _ReadOnlyField(
                            label: 'EMAIL',
                            value: controller.profile.value?.email ?? '',
                          ),
                          const SizedBox(height: 20),
                          PhoneInputField(
                            country: controller.country,
                            controller: controller.phoneController,
                          ),
                          Obx(() {
                            final error = controller.errorMessage.value;
                            if (error == null) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                error,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 40),
                          Text(
                            'PARAMÈTRES DU COMPTE',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: AppRadii.structuralRadius,
                              border: Border.all(
                                color: AppColors.outlineVariant15,
                              ),
                            ),
                            child: Column(
                              children: [
                                _SettingsRow(
                                  icon: Icons.person_add_alt,
                                  label: 'Inviter des amis',
                                  onTap: () => showAppBottomSheet(
                                    context,
                                    builder: (_) => const InviteFriendsSheet(),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: AppColors.outlineVariant15,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.notifications,
                                        color: AppColors.outline,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'Notifications',
                                          style: AppTypography.bodyMd.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Obx(
                                        () => Switch(
                                          value: controller
                                              .notificationsEnabled
                                              .value,
                                          onChanged: (value) =>
                                              controller
                                                      .notificationsEnabled
                                                      .value =
                                                  value,
                                          activeThumbColor: AppColors.volt,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: AppColors.outlineVariant15,
                                ),
                                Obx(
                                  () => _SegmentedSettingRow(
                                    label: 'Confidentialité',
                                    options: const {
                                      'standard': 'Standard',
                                      'private': 'Privé',
                                    },
                                    current: controller.privacyLevel.value
                                        .toJson(),
                                    onSelected: (value) =>
                                        controller.privacyLevel.value =
                                            ProfilePrivacyLevel.fromJson(
                                              value,
                                            ),
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: AppColors.outlineVariant15,
                                ),
                                Obx(
                                  () => _SegmentedSettingRow(
                                    label: 'Langue',
                                    options: const {'fr': 'FR', 'en': 'EN'},
                                    current: controller.language.value,
                                    onSelected: (value) =>
                                        controller.language.value = value,
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  color: AppColors.outlineVariant15,
                                ),
                                _SettingsRow(
                                  icon: Icons.logout,
                                  label: 'Déconnexion',
                                  onTap: _logout,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Builder(
                            builder: (context) {
                              final allies = Get.find<AlliesController>();
                              return Obx(() {
                                final incoming = allies.incomingRequests;
                                if (incoming.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DEMANDES REÇUES',
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: AppRadii.structuralRadius,
                                        border: Border.all(
                                          color: AppColors.outlineVariant15,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          for (final request in incoming) ...[
                                            _AllyRequestRow(
                                              request: request,
                                              onTap: () => Get.toNamed(
                                                AppRoutes.inviteFriends,
                                              ),
                                            ),
                                            if (request != incoming.last)
                                              Divider(
                                                height: 1,
                                                color:
                                                    AppColors.outlineVariant15,
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                );
                              });
                            },
                          ),
                          Builder(
                            builder: (context) {
                              final validations =
                                  Get.find<ValidationsController>();
                              return Obx(() {
                                final pendingValidations =
                                    validations.pendingValidations;
                                if (pendingValidations.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'VALIDATIONS DES ALLIÉS',
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: AppRadii.structuralRadius,
                                        border: Border.all(
                                          color: AppColors.outlineVariant15,
                                        ),
                                      ),
                                      child: _SettingsRow(
                                        icon: Icons.fact_check_outlined,
                                        label:
                                            '${pendingValidations.length} validation'
                                            '${pendingValidations.length > 1 ? 's' : ''} en attente',
                                        onTap: () => Get.toNamed(
                                          AppRoutes.allyValidations,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                );
                              });
                            },
                          ),
                          Builder(
                            builder: (context) {
                              final validations =
                                  Get.find<ValidationsController>();
                              return Obx(() {
                                final decidedValidations =
                                    validations.decidedValidations;
                                if (decidedValidations.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'HISTORIQUE DES VALIDATIONS',
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.outline,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLow,
                                        borderRadius: AppRadii.structuralRadius,
                                        border: Border.all(
                                          color: AppColors.outlineVariant15,
                                        ),
                                      ),
                                      child: _SettingsRow(
                                        icon: Icons.history,
                                        label:
                                            '${decidedValidations.length} quête'
                                            '${decidedValidations.length > 1 ? 's' : ''} '
                                            'approuvée${decidedValidations.length > 1 ? 's' : ''}'
                                            ' ou rejetée${decidedValidations.length > 1 ? 's' : ''}',
                                        onTap: () => Get.toNamed(
                                          AppRoutes.allyValidations,
                                          arguments: 'done',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                );
                              });
                            },
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
                      child: _ProfileSaveBar(
                        saving: controller.isSaving.value,
                        onSave: () => _handleSave(controller),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProfileSaveBar extends StatelessWidget {
  const _ProfileSaveBar({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border(top: BorderSide(color: AppColors.outlineVariant15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Modifications non enregistrées',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 136,
            height: 40,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: AppColors.volt,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.interactiveRadius,
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text('ENREGISTRER', style: AppTypography.labelMd),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: BorderSide(color: AppColors.outlineVariant15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.interactiveRadius,
              borderSide: const BorderSide(color: AppColors.volt),
            ),
          ),
        ),
      ],
    );
  }
}

/// Non-editable identity field — used for email, which the backend doesn't
/// allow changing via PATCH /profile/me.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: AppRadii.interactiveRadius,
            border: Border.all(color: AppColors.outlineVariant15),
          ),
          child: Text(
            value,
            style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          ),
        ),
      ],
    );
  }
}

/// A settings row whose value is picked inline via a 2-option segmented
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
                        color: entry.key == current
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: entry.key == current
                              ? AppColors.onPrimary
                              : AppColors.outline,
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.outline, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllyRequestRow extends StatelessWidget {
  const _AllyRequestRow({required this.request, required this.onTap});

  final AllyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceContainerHighest,
              child: Text(
                request.otherUser.firstName.isNotEmpty
                    ? request.otherUser.firstName[0].toUpperCase()
                    : '?',
                style: AppTypography.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Demande de ${request.otherUser.firstName} ${request.otherUser.lastName}',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.outlineVariant,
              size: 20,
            ),
          ],
        ),
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
                        profile == null
                            ? ''
                            : '${profile.firstName} ${profile.lastName}',
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
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFD8D8DE),
                            ),
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
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
