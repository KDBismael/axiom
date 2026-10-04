import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/token_storage.dart';
import '../../../core/theme/app_colors.dart';

/// Renders a user's avatar, fetched with the bearer token attached — a
/// plain [Image.network] would 401 since GET /files/:id requires auth.
/// Relative URLs (e.g. `/files/<id>`) are resolved against [ApiClient.baseApiUrl];
/// absolute http(s) URLs are used as-is. Falls back to a colored initials
/// chip — matching the initials avatars used everywhere else in the app
/// (dashboard header, leaderboard, ally lists) — or a generic person glyph
/// when no [initials] is given.
class AuthenticatedAvatarImage extends StatelessWidget {
  const AuthenticatedAvatarImage({
    super.key,
    required this.avatarUrl,
    required this.size,
    this.borderRadius,
    this.initials,
    this.backgroundColor,
  });

  final String? avatarUrl;
  final double size;

  /// Null clips to a circle; otherwise clips to this rounded-rect shape.
  final BorderRadius? borderRadius;

  final String? initials;
  final Color? backgroundColor;

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
        final image = Image.network(
          resolvedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        );
        return borderRadius == null
            ? ClipOval(child: image)
            : ClipRRect(borderRadius: borderRadius!, child: image);
      },
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerHigh,
        shape: borderRadius == null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
      ),
      child: initials == null
          ? Icon(Icons.person, color: AppColors.outline, size: size * 0.5)
          : Text(
              initials!,
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontWeight: FontWeight.w700,
                fontSize: size * 0.32,
                color: AppColors.onPrimary,
              ),
            ),
    );
  }
}
