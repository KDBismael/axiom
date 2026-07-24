import 'package:get/get.dart';
import '../routes/app_routes.dart';

/// A route + arguments pair to navigate to.
typedef RedirectTarget = ({String route, Object? arguments});

/// Holds an ally-invite token tapped while the user wasn't logged in, so it
/// can be redeemed right after their next successful login/registration
/// instead of being lost.
class PendingInviteService extends GetxService {
  String? _token;

  void stash(String token) => _token = token;

  /// The route to navigate to after a successful login/register — the
  /// pending invite if one was stashed (cleared as a side effect), home
  /// otherwise.
  RedirectTarget consumeRedirectTarget() {
    final token = _token;
    _token = null;
    if (token != null) {
      return (route: AppRoutes.invitationAlly, arguments: token);
    }
    return (route: AppRoutes.home, arguments: null);
  }
}
