import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    // No real auth backend yet — any tap just marks onboarding complete and
    // enters the app, matching the rest of the app's mock-data-now stance.
    await OnboardingService().markCompleted();
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONNEXION',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Discipline. Performance. Clarté.',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 48),
              Text(
                'EMAIL',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                decoration: _fieldDecoration(hint: 'nom@exemple.com'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MOT DE PASSE',
                    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
                  ),
                  Text(
                    'Mot de passe oublié ?',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
                decoration: _fieldDecoration(hint: '••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.outlineVariant,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(label: 'SE CONNECTER', onPressed: _signIn),
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
                label: 'Continuer avec Google',
                variant: AppButtonVariant.secondary,
                leadingIcon: Icons.g_mobiledata,
                onPressed: _signIn,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Continuer avec Apple',
                variant: AppButtonVariant.secondary,
                leadingIcon: Icons.apple,
                onPressed: _signIn,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Touch ID ou Face ID',
                variant: AppButtonVariant.secondary,
                leadingIcon: Icons.fingerprint,
                onPressed: _signIn,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.register),
                  child: Text(
                    'PAS ENCORE MEMBRE ? CRÉER UN COMPTE',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.outline,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline.withValues(alpha: 0.4)),
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
    );
  }
}
