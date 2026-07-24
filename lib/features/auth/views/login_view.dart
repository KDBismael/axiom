import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/pending_invite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateAfterAuth() {
    final target = Get.find<PendingInviteService>().consumeRedirectTarget();
    Get.offAllNamed(target.route, arguments: target.arguments);
  }

  Future<void> _signIn() async {
    await _authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (_authController.isAuthenticated) _navigateAfterAuth();
  }

  Future<void> _signInWithGoogle() async {
    await _authController.loginWithGoogle();
    if (_authController.isAuthenticated) _navigateAfterAuth();
  }

  Future<void> _signInWithApple() async {
    await _authController.loginWithApple();
    if (_authController.isAuthenticated) _navigateAfterAuth();
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
              Obx(() {
                final error = _authController.errorMessage.value;
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: AppTypography.labelMd.copyWith(color: AppColors.error),
                  ),
                );
              }),
              const SizedBox(height: 32),
              Obx(
                () => AppButton(
                  label: 'SE CONNECTER',
                  loading: _authController.activeAction.value == AuthAction.login,
                  onPressed: _authController.isLoading.value ? null : _signIn,
                ),
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
              Obx(
                () => AppButton(
                  label: 'Continuer avec Google',
                  variant: AppButtonVariant.secondary,
                  leadingIcon: Icons.g_mobiledata,
                  loading: _authController.activeAction.value == AuthAction.google,
                  onPressed: _authController.isLoading.value ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => AppButton(
                  label: 'Continuer avec Apple',
                  variant: AppButtonVariant.secondary,
                  leadingIcon: Icons.apple,
                  loading: _authController.activeAction.value == AuthAction.apple,
                  onPressed: _authController.isLoading.value ? null : _signInWithApple,
                ),
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
