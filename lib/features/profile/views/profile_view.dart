import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/controllers/validations_controller.dart';
import '../../social/models/ally_request.dart';
import '../controllers/profile_controller.dart';
import '../models/profile_model.dart';
import '../widgets/authenticated_avatar_image.dart';
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

  Future<void> _pickLanguage(ProfileController controller) {
    return _showOptionPicker(
      title: 'LANGUE',
      options: const {'fr': 'Français', 'en': 'English'},
      current: controller.language.value,
      onSelected: (value) => controller.language.value = value,
    );
  }

  Future<void> _pickPrivacyLevel(ProfileController controller) {
    return _showOptionPicker(
      title: 'CONFIDENTIALITÉ',
      options: const {'standard': 'Standard', 'private': 'Privé'},
      current: controller.privacyLevel.value.toJson(),
      onSelected: (value) =>
          controller.privacyLevel.value = ProfilePrivacyLevel.fromJson(value),
    );
  }

  Future<void> _showOptionPicker({
    required String title,
    required Map<String, String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.structuralRadius),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      title,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                  for (final entry in options.entries)
                    ListTile(
                      title: Text(
                        entry.value,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      trailing: entry.key == current
                          ? const Icon(Icons.check, color: AppColors.emerald)
                          : null,
                      onTap: () {
                        onSelected(entry.key);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
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
                  child: CircularProgressIndicator(color: AppColors.emerald),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        border: Border.all(color: AppColors.outlineVariant15),
                      ),
                      child: Column(
                        children: [
                          _SettingsRow(
                            icon: Icons.person_add_alt,
                            label: 'Inviter des amis',
                            onTap: () => Get.toNamed(AppRoutes.inviteFriends),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant15),
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
                                    value:
                                        controller.notificationsEnabled.value,
                                    onChanged: (value) =>
                                        controller.notificationsEnabled.value =
                                            value,
                                    activeThumbColor: AppColors.primaryFixed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant15),
                          Obx(
                            () => _SettingsRow(
                              icon: Icons.security,
                              label: 'Confidentialité',
                              trailingText:
                                  controller.privacyLevel.value ==
                                      ProfilePrivacyLevel.private
                                  ? 'Privé'
                                  : 'Standard',
                              onTap: () => _pickPrivacyLevel(controller),
                            ),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant15),
                          Obx(
                            () => _SettingsRow(
                              icon: Icons.language,
                              label: 'Langue',
                              trailingText: controller.language.value
                                  .toUpperCase(),
                              onTap: () => _pickLanguage(controller),
                            ),
                          ),
                          Divider(height: 1, color: AppColors.outlineVariant15),
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
                          if (incoming.isEmpty) return const SizedBox.shrink();
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
                                          color: AppColors.outlineVariant15,
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
                        final validations = Get.find<ValidationsController>();
                        return Obx(() {
                          final pendingValidations =
                              validations.pendingValidations;
                          if (pendingValidations.isEmpty)
                            return const SizedBox.shrink();
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
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.allyValidations),
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
                        final validations = Get.find<ValidationsController>();
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
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.validationHistory),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          );
                        });
                      },
                    ),
                    Text(
                      'STATISTIQUES',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppRadii.structuralRadius,
                        border: Border.all(color: AppColors.outlineVariant15),
                      ),
                      child: Builder(
                        builder: (context) {
                          final questController =
                              Get.find<QuestListController>();
                          return Obx(
                            () => Column(
                              children: [
                                _StatRow(
                                  label: 'Quêtes actives',
                                  value: '${questController.quests.length}',
                                ),
                                _StatRow(
                                  label: 'Total misé',
                                  value: formatXof(
                                    questController.totalStakeAmount,
                                  ),
                                ),
                                _StatRow(
                                  label: 'Niveau de risque',
                                  value: questController.riskLevel,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    Obx(
                      () => AppButton(
                        label: 'ENREGISTRER LES MODIFICATIONS',
                        loading: controller.isSaving.value,
                        onPressed: controller.isSaving.value
                            ? null
                            : () => _handleSave(controller),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppColors.emerald),
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
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
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(width: 4),
            ],
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

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTypography.titleLg.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
