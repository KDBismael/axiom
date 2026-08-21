import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _repository = Get.find<AuthRepository>();
  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!GetUtils.isEmail(_email.text.trim())) {
      setState(() {
        _message = "Saisissez une adresse email valide.";
        _isError = true;
      });
      return;
    }
    await _run(() async {
      final message = await _repository.requestPasswordReset(
        _email.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _message = message;
        _isError = false;
      });
    });
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 12) {
      setState(() {
        _message = 'Le code doit contenir 12 caractères.';
        _isError = true;
      });
      return;
    }
    if (_password.text.length < 8) {
      setState(() {
        _message = 'Le mot de passe doit contenir au moins 8 caractères.';
        _isError = true;
      });
      return;
    }
    if (_password.text != _confirmation.text) {
      setState(() {
        _message = 'Les mots de passe ne correspondent pas.';
        _isError = true;
      });
      return;
    }
    await _run(() async {
      await _repository.resetPassword(
        code: _code.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Mot de passe modifié',
        'Vous pouvez maintenant vous connecter.',
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message;
          _isError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Une erreur est survenue. Veuillez réessayer.';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RÉINITIALISER',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _codeSent
                    ? 'Entrez le code reçu par email et choisissez un nouveau mot de passe.'
                    : 'Recevez un code temporaire pour retrouver votre compte.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 36),
              _label('EMAIL'),
              const SizedBox(height: 8),
              TextField(
                controller: _email,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                decoration: _decoration('nom@exemple.com'),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 22),
                _label('CODE À 12 CARACTÈRES'),
                const SizedBox(height: 8),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 12,
                  decoration: _decoration(
                    'A1B2C3D4E5F6',
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 22),
                _label('NOUVEAU MOT DE PASSE'),
                const SizedBox(height: 8),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: _passwordDecoration('8 caractères minimum'),
                ),
                const SizedBox(height: 22),
                _label('CONFIRMER LE MOT DE PASSE'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmation,
                  obscureText: _obscure,
                  decoration: _passwordDecoration('Répétez le mot de passe'),
                ),
              ],
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _message!,
                    style: AppTypography.bodyMd.copyWith(
                      color: _isError ? AppColors.error : AppColors.emerald,
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              AppButton(
                label: _codeSent
                    ? 'MODIFIER LE MOT DE PASSE'
                    : 'RECEVOIR LE CODE',
                loading: _loading,
                onPressed: _loading
                    ? null
                    : (_codeSent ? _reset : _requestCode),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _requestCode,
                    child: const Text('RENVOYER LE CODE'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTypography.labelMd.copyWith(color: AppColors.outline),
  );

  InputDecoration _passwordDecoration(String hint) =>
      _decoration(hint).copyWith(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
        ),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surfaceContainerLowest,
    border: OutlineInputBorder(borderRadius: AppRadii.interactiveRadius),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadii.interactiveRadius,
      borderSide: BorderSide(color: AppColors.outlineVariant15),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.emerald),
    ),
  );
}
