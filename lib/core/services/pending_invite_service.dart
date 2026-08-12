import 'package:get/get.dart';
import '../routes/app_routes.dart';

/// A route + arguments pair to navigate to.
typedef RedirectTarget = ({String route, Object? arguments});

/// Holds an ally-invite token tapped while the user wasn't logged in, so it
/// can be redeemed right after their next successful login/registration
/// instead of being lost.
class PendingInviteService extends GetxService {
  RedirectTarget? _target;

  void stash(String token) =>
      _target = (route: AppRoutes.invitationAlly, arguments: token);

  void stashRedirect(RedirectTarget target) => _target = target;

  /// The route to navigate to after a successful login/register — the
  /// pending invite if one was stashed (cleared as a side effect), home
  /// otherwise.
  RedirectTarget consumeRedirectTarget() {
    final target = _target;
    _target = null;
    return target ?? (route: AppRoutes.home, arguments: null);
  }
}
