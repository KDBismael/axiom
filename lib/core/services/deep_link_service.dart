import 'package:app_links/app_links.dart';

/// Extracts the invite token from an `axiom://invite/<token>` deep link, or
/// null if the URI doesn't match that shape.
String? extractInviteToken(Uri uri) {
  if (uri.scheme != 'axiom' || uri.host != 'invite') return null;
  if (uri.pathSegments.isEmpty) return null;
  return uri.pathSegments.first;
}

/// Thin wrapper around [AppLinks] — only handles the custom `axiom://`
/// scheme (no Universal Links/App Links, no deferred deep linking: the link
/// only opens the app if it's already installed, per the current plan).
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
