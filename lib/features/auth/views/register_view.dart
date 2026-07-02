import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // No real auth backend yet — creating an account just marks onboarding
    // complete and enters the app, matching the rest of the app's
    // mock-data-now stance.
    await OnboardingService().markCompleted();
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AXIOM',
                    style: AppTypography.titleLg.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.02 * 20,
                    ),
                  ),
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.close, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 32, height: 1, color: AppColors.outlineVariant),
                        const SizedBox(width: 8),
                        Text(
                          'NOUVEL ACCÈS',
                          style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "REJOINDRE L'ÉLITE",
                      style: AppTypography.displayLg.copyWith(
                        color: AppColors.primary,
                        fontSize: 40,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: _UnderlineField(
                            label: 'PRÉNOM',
                            hint: 'JEAN',
                            controller: _firstNameController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _UnderlineField(
                            label: 'NOM',
                            hint: 'DUPONT',
                            controller: _lastNameController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _UnderlineField(
                      label: 'EMAIL',
                      hint: 'contact@axiom.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    _UnderlineField(
                      label: 'NUMÉRO DE TÉLÉPHONE',
                      hint: '+225 07 00 00 00 00',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    _UnderlineField(
                      label: 'MOT DE PASSE',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 24),
                    _UnderlineField(
                      label: 'CONFIRMER LE MOT DE PASSE',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      onToggleObscure: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AppButton(
                      label: 'CRÉER MON COMPTE',
                      variant: AppButtonVariant.lustre,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: _termsAccepted ? _register : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.outlineVariant15)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OU',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outline,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.outlineVariant15)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: "S'inscrire avec Google",
                      variant: AppButtonVariant.secondary,
                      leadingIcon: Icons.g_mobiledata,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: "S'inscrire avec Apple",
                      variant: AppButtonVariant.secondary,
                      leadingIcon: Icons.apple,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _termsAccepted,
                                onChanged: (value) =>
                                    setState(() => _termsAccepted = value ?? false),
                                activeColor: AppColors.primaryFixed,
                                side: BorderSide(color: AppColors.outlineVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "J'accepte les conditions",
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.outline,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Get.offNamed(AppRoutes.login),
                          child: Text(
                            'DÉJÀ MEMBRE ?',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.outline,
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'PROTÉGÉ PAR AXIOM ENCRYPT',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.outline.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onToggleObscure,
  });

  final String label;
  final String hint;
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
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd.copyWith(
              color: AppColors.surfaceBright.withValues(alpha: 0.5),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primaryFixed),
            ),
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.outline,
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  ),
          ),
        ),
      ],
    );
  }
}
