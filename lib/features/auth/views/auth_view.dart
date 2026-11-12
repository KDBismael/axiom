import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/legal_links.dart';
import '../../payments/services/url_opener.dart';
import '../../../core/services/pending_invite_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/branding/ndeli_wordmark.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../profile/models/country.dart';
import '../../profile/widgets/phone_input_field.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';

enum _AuthMode { login, register, forgot }

/// The merged login / register / forgot-password screen: one scaffold with
/// a segmented Connexion/Inscription tab switching mode via local state,
/// matching the "Ndeli — Arène" mockup's single-screen AUTH block exactly
/// (previously three separate routes/screens).
/// Signup fields kept in memory while the app process lives, so leaving
/// the screen (back twice, opening the terms in a browser, the route being
/// rebuilt) doesn't wipe what was typed. Passwords are never kept.
class _SignupDraft {
  static String firstName = '';
  static String lastName = '';
  static String email = '';
  static String phone = '';
  static Country? country;
  static bool termsAccepted = false;

  // Email is shared with the login form, so it doesn't count as a
  // signup in progress on its own.
  static bool get isEmpty =>
      firstName.isEmpty && lastName.isEmpty && phone.isEmpty;

  static void clear() {
    firstName = lastName = email = phone = '';
    country = null;
    termsAccepted = false;
  }
}

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  _AuthMode _mode =
      Get.arguments == 'register' || !_SignupDraft.isEmpty
      ? _AuthMode.register
      : _AuthMode.login;

  // Login / register fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _country = Rx<Country>(xofZoneCountries.first);
  bool _termsAccepted = false;

  // Forgot-password sub-flow
  final _forgotEmailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmController = TextEditingController();
  bool _codeSent = false;
  bool _forgotLoading = false;
  String? _forgotMessage;
  bool _forgotIsError = false;

  final _authController = Get.find<AuthController>();
  final _authRepository = Get.find<AuthRepository>();

  Worker? _countryWorker;

  void _saveDraft() {
    _SignupDraft.firstName = _firstNameController.text;
    _SignupDraft.lastName = _lastNameController.text;
    _SignupDraft.email = _emailController.text;
    _SignupDraft.phone = _phoneController.text;
    _SignupDraft.country = _country.value;
    _SignupDraft.termsAccepted = _termsAccepted;
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.text = _SignupDraft.firstName;
    _lastNameController.text = _SignupDraft.lastName;
    _emailController.text = _SignupDraft.email;
    _phoneController.text = _SignupDraft.phone;
    _country.value = _SignupDraft.country ?? _country.value;
    _termsAccepted = _SignupDraft.termsAccepted;
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _phoneController,
    ]) {
      controller.addListener(_saveDraft);
    }
    _countryWorker = ever<Country>(_country, (_) => _saveDraft());
    // A stale error ("Le prénom est requis") must not linger once the
    // user starts fixing the form.
    final fields = {
      'email': _emailController,
      'password': _passwordController,
      'firstName': _firstNameController,
      'lastName': _lastNameController,
      'phone': _phoneController,
      'confirm': _confirmPasswordController,
    };
    fields.forEach((field, controller) {
      controller.addListener(() => _clearError(field));
    });
  }

  /// Per-field signup errors, shown under each field. Editing a field
  /// clears only its own error (and any server error).
  final Map<String, String> _fieldErrors = {};

  void _clearError(String field) {
    if (_fieldErrors.containsKey(field)) {
      setState(() => _fieldErrors.remove(field));
    }
    // Keep the summary in sync with what's still flagged.
    _authController.errorMessage.value = _fieldErrors.isEmpty
        ? null
        : _summaryFor(_fieldErrors.length);
  }

  String _summaryFor(int count) => count > 1
      ? 'Corrige les $count champs signalés en rouge.'
      : 'Corrige le champ signalé en rouge.';

  final _scrollController = ScrollController();

  static final _personName = RegExp(r"^[\p{L}][\p{L}\p{M} '’-]*$", unicode: true);

  String? _nameError(String value, String label) {
    final name = value.trim();
    if (name.isEmpty) return '$label est requis.';
    if (name.length > 50) return '$label ne peut pas dépasser 50 caractères.';
    if (!_personName.hasMatch(name)) {
      return '$label ne peut contenir que des lettres, espaces, tirets et apostrophes.';
    }
    return null;
  }

  Map<String, String> _validateSignup() {
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final errors = <String, String?>{
      'firstName': _nameError(_firstNameController.text, 'Le prénom'),
      'lastName': _nameError(_lastNameController.text, 'Le nom'),
      'email': GetUtils.isEmail(_emailController.text.trim())
          ? null
          : "L'e-mail n'est pas valide.",
      'phone': phoneDigits.isEmpty || _country.value.isValidLocalNumber(phoneDigits)
          ? null
          : 'Un numéro (${_country.value.name}) compte '
                '${_country.value.localLength} chiffres, ex. ${_country.value.example}.',
      'password': _passwordController.text.length >= 8
          ? null
          : 'Le mot de passe doit contenir au moins 8 caractères.',
      'confirm': _confirmPasswordController.text.isEmpty
          ? 'Confirme ton mot de passe.'
          : _confirmPasswordController.text != _passwordController.text
          ? 'Les deux mots de passe ne correspondent pas.'
          : null,
      'terms': _termsAccepted
          ? null
          : "Coche « J'accepte les conditions » pour créer ton compte.",
    };
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  Widget _errorFor(String field) {
    final error = _fieldErrors[field];
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        error,
        style: AppTypography.bodyMd.copyWith(color: AppColors.error, fontSize: 12.5),
      ),
    );
  }

  late final _termsLink = TapGestureRecognizer()
    ..onTap = () => _openLink(LegalLinks.terms);
  late final _privacyLink = TapGestureRecognizer()
    ..onTap = () => _openLink(LegalLinks.privacy);

  Future<void> _openLink(String url) async {
    final opener = Get.isRegistered<UrlOpener>() ? Get.find<UrlOpener>() : UrlOpener();
    if (!await opener.open(url)) {
      Get.snackbar('Lien indisponible', 'Ouvre $url dans ton navigateur.');
    }
  }

  @override
  void dispose() {
    _countryWorker?.dispose();
    _termsLink.dispose();
    _scrollController.dispose();
    _privacyLink.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _fieldErrors.clear();
      _authController.errorMessage.value = null;
    });
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
    if (_authController.isAuthenticated) {
      _SignupDraft.clear();
      _navigateAfterAuth();
    }
  }

  Future<void> _register() async {
    // Everything checkable locally is reported in one go, each under its
    // own field, instead of one server error per tap.
    final errors = _validateSignup();
    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) {
      _authController.errorMessage.value = _summaryFor(errors.length);
      // The identity fields sit above the button: bring them into view.
      if (errors.keys.any(
            (field) => const ['firstName', 'lastName', 'email', 'phone'].contains(field),
          ) &&
          _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      return;
    }
    await _authController.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          // "07 01 02 03 04" → "+2250701020304" (the backend expects E.164).
          : '${_country.value.dialCode}${_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '')}',
    );
    if (_authController.isAuthenticated) {
      _SignupDraft.clear();
      _navigateAfterAuth();
      return;
    }
    // Server-side field errors belong under their field too.
    final error = _authController.errorMessage.value ?? '';
    final field = error.contains('téléphone')
        ? 'phone'
        : error.contains('email') || error.contains('e-mail')
        ? 'email'
        : null;
    if (field != null) setState(() => _fieldErrors[field] = error);
  }

  Future<void> _continueWithGoogle() async {
    await _authController.loginWithGoogle();
    if (_authController.isAuthenticated) _navigateAfterAuth();
  }

  Future<void> _continueWithApple() async {
    await _authController.loginWithApple();
    if (_authController.isAuthenticated) _navigateAfterAuth();
  }

  Future<void> _requestCode() async {
    if (!GetUtils.isEmail(_forgotEmailController.text.trim())) {
      setState(() {
        _forgotMessage = 'Saisissez une adresse email valide.';
        _forgotIsError = true;
      });
      return;
    }
    await _runForgot(() async {
      final message = await _authRepository.requestPasswordReset(
        _forgotEmailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _forgotMessage = message;
        _forgotIsError = false;
      });
    });
  }

  Future<void> _resetPassword() async {
    if (_codeController.text.trim().length != 12) {
      setState(() {
        _forgotMessage = 'Le code doit contenir 12 caractères.';
        _forgotIsError = true;
      });
      return;
    }
    if (_newPasswordController.text.length < 8) {
      setState(() {
        _forgotMessage = 'Le mot de passe doit contenir au moins 8 caractères.';
        _forgotIsError = true;
      });
      return;
    }
    if (_newPasswordController.text != _newPasswordConfirmController.text) {
      setState(() {
        _forgotMessage = 'Les mots de passe ne correspondent pas.';
        _forgotIsError = true;
      });
      return;
    }
    await _runForgot(() async {
      await _authRepository.resetPassword(
        code: _codeController.text.trim(),
        password: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() {
        _codeSent = false;
        _mode = _AuthMode.login;
      });
      Get.snackbar('Mot de passe modifié', 'Tu peux maintenant te connecter.');
    });
  }

  Future<void> _runForgot(Future<void> Function() action) async {
    setState(() {
      _forgotLoading = true;
      _forgotMessage = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _forgotMessage = error.message;
          _forgotIsError = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _forgotMessage = 'Une erreur est survenue. Veuillez réessayer.';
          _forgotIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _forgotLoading = false);
    }
  }

  String get _title => switch (_mode) {
        _AuthMode.login => 'Content de te revoir.',
        _AuthMode.register => "Entre dans l'arène.",
        _AuthMode.forgot => 'Mot de passe oublié',
      };

  @override
  Widget build(BuildContext context) {
    // Android back on Inscription / Mot de passe oublié returns to
    // Connexion instead of quitting the app and losing the form.
    return PopScope(
      canPop: _mode == _AuthMode.login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setMode(_AuthMode.login);
      },
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const NdeliWordmark(),
              const SizedBox(height: 22),
              Text(_title, style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
              const SizedBox(height: 22),
              if (_mode != _AuthMode.forgot) _buildTabs(),
              if (_mode != _AuthMode.forgot) const SizedBox(height: 22),
              _buildFields(),
              const SizedBox(height: 22),
              _buildPrimaryCta(),
              if (_mode != _AuthMode.forgot)
                Center(
                  child: TextButton(
                    onPressed: () => _setMode(
                      _mode == _AuthMode.login
                          ? _AuthMode.register
                          : _AuthMode.login,
                    ),
                    child: Text(
                      _mode == _AuthMode.login
                          ? 'Pas encore de compte ? Inscris-toi'
                          : 'Déjà un compte ? Connecte-toi',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        color: AppColors.volt,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              if (_mode == _AuthMode.forgot) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _setMode(_AuthMode.login),
                    child: Text(
                      '← Retour à la connexion',
                      style: const TextStyle(fontFamily: 'Geist', color: AppColors.outline, fontSize: 14),
                    ),
                  ),
                ),
              ],
              if (_mode != _AuthMode.forgot) ...[
                const SizedBox(height: 22),
                _buildOrDivider(),
                const SizedBox(height: 12),
                _buildSocialButtons(),
              ],
              if (_mode == _AuthMode.register) ...[
                const SizedBox(height: 26),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: 0.7853981633974483,
                        child: Container(width: 8, height: 8, color: AppColors.volt),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CONNEXION SÉCURISÉE',
                        style: AppTypography.labelMd.copyWith(
                          fontSize: 12.5,
                          color: AppColors.outlineMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    Widget tab(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? AppColors.onPrimary : AppColors.outline,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.interactiveRadius,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          tab('Connexion', _mode == _AuthMode.login, () => _setMode(_AuthMode.login)),
          tab('Inscription', _mode == _AuthMode.register, () => _setMode(_AuthMode.register)),
        ],
      ),
    );
  }

  Widget _buildFields() {
    if (_mode == _AuthMode.forgot) return _buildForgotFields();

    final fields = <Widget>[];
    if (_mode == _AuthMode.register) {
      fields.addAll([
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Prénom',
                    hint: 'Khady',
                    controller: _firstNameController,
                    textInputAction: TextInputAction.next,
                  ),
                  _errorFor('firstName'),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Nom',
                    hint: 'Ndiaye',
                    controller: _lastNameController,
                    textInputAction: TextInputAction.next,
                  ),
                  _errorFor('lastName'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ]);
    }

    fields.add(
      AppTextField(
        key: const ValueKey('auth-email'),
        label: 'E-mail',
        hint: 'khady@exemple.sn',
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
      ),
    );
    if (_mode == _AuthMode.register) fields.add(_errorFor('email'));

    if (_mode == _AuthMode.register) {
      fields.addAll([
        const SizedBox(height: 14),
        PhoneInputField(
          country: _country,
          controller: _phoneController,
          label: 'TÉLÉPHONE (FACULTATIF)',
        ),
        _errorFor('phone'),
      ]);
    }

    fields.addAll([
      const SizedBox(height: 14),
      AppTextField(
        key: const ValueKey('auth-password'),
        label: 'Mot de passe',
        hint: _mode == _AuthMode.register
            ? '8 caractères minimum'
            : 'Ton mot de passe',
        controller: _passwordController,
        obscureText: true,
        allowObscureToggle: true,
        textInputAction: _mode == _AuthMode.register
            ? TextInputAction.next
            : TextInputAction.done,
      ),
      if (_mode == _AuthMode.register) _errorFor('password'),
    ]);

    if (_mode == _AuthMode.register) {
      fields.addAll([
        const SizedBox(height: 14),
        AppTextField(
          key: const ValueKey('auth-confirm-password'),
          label: 'Confirmer le mot de passe',
          hint: 'Répète le mot de passe',
          controller: _confirmPasswordController,
          obscureText: true,
          allowObscureToggle: true,
        ),
        _errorFor('confirm'),
        const SizedBox(height: 14),
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() => _termsAccepted = value ?? false);
                  _SignupDraft.termsAccepted = _termsAccepted;
                  _clearError('terms');
                },
                activeColor: AppColors.volt,
                checkColor: AppColors.onPrimary,
                side: BorderSide(color: AppColors.outlineVariantStrong),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _termsAccepted = !_termsAccepted);
                  _SignupDraft.termsAccepted = _termsAccepted;
                  _clearError('terms');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodyMd.copyWith(color: AppColors.outline, fontSize: 13),
                      children: [
                        const TextSpan(text: "J'accepte les "),
                        TextSpan(
                          text: "conditions d'utilisation",
                          style: const TextStyle(
                            color: AppColors.volt,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _termsLink,
                        ),
                        const TextSpan(text: ' et la '),
                        TextSpan(
                          text: 'politique de confidentialité',
                          style: const TextStyle(
                            color: AppColors.volt,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _privacyLink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _errorFor('terms'),
      ]);
    }

    if (_mode == _AuthMode.login) {
      fields.addAll([
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _setMode(_AuthMode.forgot),
            child: Text(
              'Mot de passe oublié ?',
              style: TextStyle(fontFamily: 'Geist', color: AppColors.volt, fontSize: 13.5),
            ),
          ),
        ),
      ]);
    }

    fields.add(
      Obx(() {
        final error = _authController.errorMessage.value;
        if (error == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(error, style: AppTypography.bodyMd.copyWith(color: AppColors.error)),
        );
      }),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: fields);
  }

  Widget _buildForgotFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _codeSent
              ? 'Entrez le code reçu par email et choisis un nouveau mot de passe.'
              : 'Reçois un code temporaire pour retrouver ton compte.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: 18),
        AppTextField(
          label: 'E-mail',
          hint: 'khady@exemple.sn',
          controller: _forgotEmailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_codeSent,
        ),
        if (_codeSent) ...[
          const SizedBox(height: 14),
          AppTextField(
            label: 'Code à 12 caractères',
            hint: 'A1B2C3D4E5F6',
            controller: _codeController,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Nouveau mot de passe',
            hint: '8 caractères minimum',
            controller: _newPasswordController,
            obscureText: true,
            allowObscureToggle: true,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Confirmer le mot de passe',
            hint: 'Répète le mot de passe',
            controller: _newPasswordConfirmController,
            obscureText: true,
            allowObscureToggle: true,
          ),
        ],
        if (_forgotMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              _forgotMessage!,
              style: AppTypography.bodyMd.copyWith(
                color: _forgotIsError ? AppColors.error : AppColors.volt,
              ),
            ),
          ),
        if (_codeSent)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotLoading ? null : _requestCode,
              child: const Text(
                'RENVOYER LE CODE',
                style: TextStyle(fontFamily: 'Geist Mono', color: AppColors.outline, fontSize: 11.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryCta() {
    switch (_mode) {
      case _AuthMode.login:
        return Obx(
          () => AppButton(
            label: 'SE CONNECTER',
            loading: _authController.activeAction.value == AuthAction.login,
            onPressed: _authController.isLoading.value ? null : _signIn,
          ),
        );
      case _AuthMode.register:
        return Obx(
          () => AppButton(
            label: 'CRÉER MON COMPTE',
            loading: _authController.activeAction.value == AuthAction.register,
            // Always tappable: _register explains what's missing instead
            // of a silently greyed-out button.
            onPressed: _authController.isLoading.value ? null : _register,
          ),
        );
      case _AuthMode.forgot:
        return AppButton(
          label: _codeSent ? 'MODIFIER LE MOT DE PASSE' : 'ENVOYER LE LIEN',
          loading: _forgotLoading,
          onPressed: _forgotLoading ? null : (_codeSent ? _resetPassword : _requestCode),
        );
    }
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: AppTypography.labelMd.copyWith(color: AppColors.outlineFaint, fontSize: 11),
          ),
        ),
        Expanded(child: Divider(color: AppColors.outlineVariant)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    final googleLabel = _mode == _AuthMode.register ? "S'inscrire avec Google" : 'Continuer avec Google';
    final appleLabel = _mode == _AuthMode.register ? "S'inscrire avec Apple" : 'Continuer avec Apple';
    return Column(
      children: [
        Obx(
          () => AppButton(
            label: googleLabel,
            variant: AppButtonVariant.secondary,
            leadingIcon: Icons.g_mobiledata,
            loading: _authController.activeAction.value == AuthAction.google,
            onPressed: _authController.isLoading.value ? null : _continueWithGoogle,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => AppButton(
            label: appleLabel,
            variant: AppButtonVariant.secondary,
            leadingIcon: Icons.apple,
            loading: _authController.activeAction.value == AuthAction.apple,
            onPressed: _authController.isLoading.value ? null : _continueWithApple,
          ),
        ),
      ],
    );
  }
}
