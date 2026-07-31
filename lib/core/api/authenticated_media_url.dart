import 'package:get/get.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Resolves a possibly-relative media path against [ApiClient.baseApiUrl]
/// and attaches the bearer token as a request header — shared by every
/// widget that fetches an authenticated image/video (GET on these routes
/// 401s without it).
Future<(String url, Map<String, String>? headers)> resolveAuthenticatedMedia(
  String path,
) async {
  final url = path.startsWith('http') ? path : '${ApiClient.baseApiUrl}$path';
  final token = await Get.find<TokenStorage>().readAccessToken();
  return (url, token != null ? {'Authorization': 'Bearer $token'} : null);
}
