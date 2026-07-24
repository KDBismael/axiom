import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/theme/app_colors.dart';

/// Renders a user's avatar, fetched with the bearer token attached — a
/// plain [Image.network] would 401 since GET /files/:id requires auth.
/// Relative URLs (e.g. `/files/<id>`) are resolved against [ApiClient.baseApiUrl];
/// absolute http(s) URLs are used as-is.
class AuthenticatedAvatarImage extends StatelessWidget {
  const AuthenticatedAvatarImage({super.key, required this.avatarUrl, required this.size});

  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return _fallback();

    final resolvedUrl = url.startsWith('http') ? url : '${ApiClient.baseApiUrl}$url';

    return FutureBuilder<String?>(
      future: Get.find<TokenStorage>().readAccessToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return _fallback();
        final token = snapshot.data;
        return ClipOval(
          child: Image.network(
            resolvedUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            headers: token != null ? {'Authorization': 'Bearer $token'} : null,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: AppColors.outline, size: size * 0.5),
    );
  }
}
