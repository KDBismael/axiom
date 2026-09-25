import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'token_storage.dart';

/// Thin GetConnect-based HTTP client shared by every repository that talks
/// to the axiom-backend API. Attaches the bearer token to authenticated
/// requests and transparently refreshes+retries once on a 401.
class ApiClient extends GetConnect {
  ApiClient({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  /// Shared by every concurrently-401ing request so only one of them
  /// actually calls /auth/refresh — the backend rotates (single-use)
  /// refresh tokens with no grace period, so a second concurrent call
  /// using the same (now-revoked) refresh token would otherwise fail and
  /// wrongly force a logout even though the session was still refreshable.
  Future<_RefreshOutcome>? _refreshInFlight;

  /// Guards against firing the login redirect once per failed concurrent
  /// request — without it, N requests failing together fire N redirects
  /// back to back.
  bool _loggedOut = false;

  /// Endpoints that never carry (or need) a bearer token, and must never
  /// trigger the refresh authenticator on a 401 — refreshing there would
  /// either be meaningless (no token to attach) or recurse into itself
  /// (/auth/refresh calling /auth/refresh).
  static const _publicPaths = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/google',
    '/auth/apple',
    '/auth/forgot-password',
    '/auth/reset-password',
  ];

  static const String baseApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  @override
  void onInit() {
    httpClient.baseUrl = baseApiUrl;
    httpClient.timeout = const Duration(seconds: 20);
    httpClient.maxAuthRetries = 1;

    httpClient.addRequestModifier<dynamic>((request) async {
      if (_isPublicPath(request.url.path)) return request;
      final token = await _tokenStorage.readAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });

    httpClient.addAuthenticator<dynamic>((request) async {
      if (_isPublicPath(request.url.path)) return request;

      final outcome = await _ensureFreshToken();
      switch (outcome) {
        case _RefreshOutcome.rejected:
          await _handleRefreshFailure();
          return request;
        case _RefreshOutcome.unavailable:
          // Couldn't even ask the backend (offline, timeout, a 5xx) — that
          // says nothing about whether the refresh token is still good, so
          // don't force a logout over it. Let this one request go through
          // and fail normally instead.
          return request;
        case _RefreshOutcome.success:
          final newAccess = await _tokenStorage.readAccessToken();
          if (newAccess != null) {
            request.headers['Authorization'] = 'Bearer $newAccess';
          }
          return request;
      }
    });

    super.onInit();
  }

  bool _isPublicPath(String path) => _publicPaths.any((p) => path.endsWith(p));

  /// Resets the "already logged out" latch — call this right after a fresh,
  /// successful manual login/register, since [_loggedOut] otherwise only
  /// resets inside a successful [_refresh] and would otherwise stay stuck
  /// from a previous forced logout.
  void resetLoggedOutState() => _loggedOut = false;

  /// Runs the /auth/refresh call at most once for any set of requests that
  /// 401 concurrently — later callers await the same in-flight [Future]
  /// instead of racing their own refresh against it.
  Future<_RefreshOutcome> _ensureFreshToken() {
    return _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<_RefreshOutcome> _refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return _RefreshOutcome.rejected;

    final response = await post('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    if (response.status.connectionError || response.status.isServerError) {
      return _RefreshOutcome.unavailable;
    }
    final body = response.body;
    if (response.isOk && body is Map<String, dynamic>) {
      final newAccess = body['accessToken'] as String;
      final newRefresh = body['refreshToken'] as String;
      await _tokenStorage.saveTokenPair(access: newAccess, refresh: newRefresh);
      _loggedOut = false;
      return _RefreshOutcome.success;
    }
    return _RefreshOutcome.rejected;
  }

  Future<void> _handleRefreshFailure() async {
    if (_loggedOut) return;
    _loggedOut = true;
    await _tokenStorage.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}

/// Outcome of a single /auth/refresh attempt — kept distinct from a plain
/// bool so callers can tell "the backend rejected this refresh token"
/// ([rejected]) apart from "couldn't even ask" ([unavailable]); only the
/// former should ever force a logout.
enum _RefreshOutcome { success, rejected, unavailable }
