import 'package:get/get.dart';
import '../../../core/api/token_storage.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/apple_auth_service.dart';
import '../services/google_auth_service.dart';

/// Which auth request is currently in flight, if any — lets each button in
/// the UI show its own spinner instead of every button reacting to one
/// shared [AuthController.isLoading] flag.
enum AuthAction { login, register, google, apple }

/// App-lifetime auth state — registered once in [InitialBinding] as a
/// permanent GetxService so every screen can read/react to it via
/// `Get.find<AuthController>()`.
class AuthController extends GetxService {
  AuthController({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
    required GoogleAuthService googleAuthService,
    required AppleAuthService appleAuthService,
  })  : _authRepository = authRepository,
        _tokenStorage = tokenStorage,
        _googleAuthService = googleAuthService,
        _appleAuthService = appleAuthService;

  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final GoogleAuthService _googleAuthService;
  final AppleAuthService _appleAuthService;

  final user = Rxn<User>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  /// Which specific action (login/register/google/apple) is in flight, or
  /// null when idle — drives per-button loading state in the UI.
  final activeAction = Rxn<AuthAction>();

  bool get isAuthenticated => user.value != null;

  /// Called once at startup, after tokens (if any) have had a chance to be
  /// read: restores the session by fetching the current user, or clears
  /// stale tokens if that fails.
  Future<void> restoreSession() async {
    if (!await _tokenStorage.hasTokens()) {
      user.value = null;
      return;
    }
    try {
      user.value = await _authRepository.fetchMe();
    } catch (_) {
      await _tokenStorage.clear();
      user.value = null;
    }
  }

  Future<void> login({required String email, required String password}) {
    return _runAuthAction(
      AuthAction.login,
      () => _authRepository.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) {
    return _runAuthAction(
      AuthAction.register,
      () => _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      ),
    );
  }

  Future<void> loginWithGoogle() {
    return _runAuthAction(AuthAction.google, () async {
      final idToken = await _googleAuthService.signIn();
      if (idToken == null) throw AuthException('Connexion Google annulée.');
      return _authRepository.loginWithGoogle(idToken);
    });
  }

  Future<void> loginWithApple() {
    return _runAuthAction(AuthAction.apple, () async {
      final payload = await _appleAuthService.signIn();
      if (payload == null) throw AuthException('Connexion Apple annulée.');
      return _authRepository.loginWithApple(
        idToken: payload.idToken,
        firstName: payload.firstName,
        lastName: payload.lastName,
      );
    });
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _authRepository.logout(refreshToken);
      } catch (_) {
        // Best-effort server-side revoke — local state is cleared either way.
      }
    }
    await _tokenStorage.clear();
    user.value = null;
  }

  Future<void> _runAuthAction(AuthAction action, Future<AuthResult> Function() request) async {
    isLoading.value = true;
    activeAction.value = action;
    errorMessage.value = null;
    try {
      final result = await request();
      await _tokenStorage.saveTokenPair(access: result.accessToken, refresh: result.refreshToken);
      user.value = result.user;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      // Native SDK failures (Google/Apple sign-in) surface as plain
      // exceptions, not AuthException — never let those propagate
      // unhandled out of a button tap.
      errorMessage.value = 'Une erreur est survenue. Veuillez réessayer.';
    } finally {
      isLoading.value = false;
      activeAction.value = null;
    }
  }
}
