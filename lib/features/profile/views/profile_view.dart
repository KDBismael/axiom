import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/currency.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/navigation/glass_chrome.dart';
import '../../quests/controllers/quest_list_controller.dart';

/// "Profile" tab — identity/security settings plus real quest stats.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _nameController = TextEditingController(text: 'Jean-Marc Vallet');
  final _emailController = TextEditingController(text: 'jm.vallet@axiom.io');
  final _passwordController = TextEditingController(text: 'axiom-secret');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
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
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: GlassChrome(
            safeAreaTop: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    child: Icon(Icons.person, size: 16, color: AppColors.outline),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AXIOM',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02 * 20,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.settings, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: AppRadii.structuralRadius,
                              border: Border.all(color: AppColors.outlineVariant15),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: AppColors.outline,
                            ),
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
                      const SizedBox(height: 24),
                      Text(
                        'Profil Utilisateur',
                        style: AppTypography.displayLg.copyWith(
                          color: AppColors.primary,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'IDENTITÉ ET SÉCURITÉ',
                        style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _ProfileField(label: 'NOM', controller: _nameController),
                const SizedBox(height: 20),
                _ProfileField(
                  label: 'EMAIL',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _ProfileField(
                  label: 'MOT DE PASSE',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 40),
                Text(
                  'PARAMÈTRES DU COMPTE',
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
                      _SettingsRow(
                        icon: Icons.person_add_alt,
                        label: 'Inviter des amis',
                        onTap: () => Get.toNamed(AppRoutes.inviteFriends),
                      ),
                      Divider(height: 1, color: AppColors.outlineVariant15),
                      const _SettingsRow(icon: Icons.notifications, label: 'Notifications'),
                      Divider(height: 1, color: AppColors.outlineVariant15),
                      const _SettingsRow(icon: Icons.security, label: 'Confidentialité'),
                      Divider(height: 1, color: AppColors.outlineVariant15),
                      const _SettingsRow(
                        icon: Icons.language,
                        label: 'Langue',
                        trailingText: 'FR',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'STATISTIQUES',
                  style: AppTypography.labelMd.copyWith(color: AppColors.outline),
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
                      final controller = Get.find<QuestListController>();
                      return Obx(
                        () => Column(
                          children: [
                            _StatRow(
                              label: 'Quêtes actives',
                              value: '${controller.quests.length}',
                            ),
                            _StatRow(
                              label: 'Total misé',
                              value: formatXof(controller.totalStakeAmount),
                            ),
                            _StatRow(
                              label: 'Niveau de risque',
                              value: controller.riskLevel,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(label: 'ENREGISTRER LES MODIFICATIONS', onPressed: _save),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMd.copyWith(color: AppColors.outline)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.outline,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  ),
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
            const Icon(Icons.chevron_right, color: AppColors.outlineVariant, size: 20),
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
