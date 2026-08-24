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
  Future<bool>? _refreshInFlight;

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

      final refreshed = await _ensureFreshToken();
      if (!refreshed) {
        await _handleRefreshFailure();
        return request;
      }

      final newAccess = await _tokenStorage.readAccessToken();
      if (newAccess != null) {
        request.headers['Authorization'] = 'Bearer $newAccess';
      }
      return request;
    });

    super.onInit();
  }

  bool _isPublicPath(String path) => _publicPaths.any((p) => path.endsWith(p));

  /// Runs the /auth/refresh call at most once for any set of requests that
  /// 401 concurrently — later callers await the same in-flight [Future]
  /// instead of racing their own refresh against it.
  Future<bool> _ensureFreshToken() {
    return _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;

    final response = await post('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    final body = response.body;
    if (response.isOk && body is Map<String, dynamic>) {
      final newAccess = body['accessToken'] as String;
      final newRefresh = body['refreshToken'] as String;
      await _tokenStorage.saveTokenPair(access: newAccess, refresh: newRefresh);
      _loggedOut = false;
      return true;
    }
    return false;
  }

  Future<void> _handleRefreshFailure() async {
    if (_loggedOut) return;
    _loggedOut = true;
    await _tokenStorage.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}
