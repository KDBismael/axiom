import 'package:get/get.dart';
import '../routes/app_routes.dart';
import 'token_storage.dart';

/// Thin GetConnect-based HTTP client shared by every repository that talks
/// to the axiom-backend API. Attaches the bearer token to authenticated
/// requests and transparently refreshes+retries once on a 401.
class ApiClient extends GetConnect {
  ApiClient({required TokenStorage tokenStorage}) : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

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

      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        await _handleRefreshFailure();
        return request;
      }

      final response = await post('/auth/refresh', {'refreshToken': refreshToken});
      final body = response.body;
      if (response.isOk && body is Map<String, dynamic>) {
        final newAccess = body['accessToken'] as String;
        final newRefresh = body['refreshToken'] as String;
        await _tokenStorage.saveTokenPair(access: newAccess, refresh: newRefresh);
        request.headers['Authorization'] = 'Bearer $newAccess';
        return request;
      }

      await _handleRefreshFailure();
      return request;
    });

    super.onInit();
  }

  bool _isPublicPath(String path) => _publicPaths.any((p) => path.endsWith(p));

  Future<void> _handleRefreshFailure() async {
    await _tokenStorage.clear();
    Get.offAllNamed(AppRoutes.login);
  }
}
