import 'package:app_links/app_links.dart';

/// Extracts an invite token from the verified HTTPS link or the legacy
/// `axiom://` custom scheme.
String? extractInviteToken(Uri uri) {
  if (uri.scheme == 'axiom' && uri.host == 'invite') {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (uri.scheme != 'https' || uri.host != 'links.ndeli.tech') return null;
  if (uri.pathSegments.length != 2 || uri.pathSegments.first != 'invite') {
    return null;
  }
  return uri.pathSegments[1].isEmpty ? null : uri.pathSegments[1];
}

/// Thin wrapper around [AppLinks] for verified links and legacy scheme links.
class DeepLinkService {
  DeepLinkService([AppLinks? appLinks]) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// The token from the link that launched the app cold, if any.
  Future<String?> getInitialInviteToken() async {
    final uri = await _appLinks.getInitialLink();
    return uri == null ? null : extractInviteToken(uri);
  }

  /// Tokens from links tapped while the app is already running.
  Stream<String> get inviteTokenStream => _appLinks.uriLinkStream
      .map(extractInviteToken)
      .where((token) => token != null)
      .cast<String>();
}
