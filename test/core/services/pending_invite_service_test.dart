import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/core/routes/app_routes.dart';
import 'package:axiom/core/services/pending_invite_service.dart';

void main() {
  late PendingInviteService service;

  setUp(() {
    service = PendingInviteService();
  });

  group('PendingInviteService.consumeRedirectTarget', () {
    test('redirects home when nothing was stashed', () {
      final target = service.consumeRedirectTarget();

      expect(target.route, AppRoutes.home);
      expect(target.arguments, isNull);
    });

    test('redirects to the invitation screen with the stashed token', () {
      service.stash('tok-abc');

      final target = service.consumeRedirectTarget();

      expect(target.route, AppRoutes.invitationAlly);
      expect(target.arguments, 'tok-abc');
    });

    test('clears the stashed token after consuming it once', () {
      service.stash('tok-abc');
      service.consumeRedirectTarget();

      final second = service.consumeRedirectTarget();

      expect(second.route, AppRoutes.home);
      expect(second.arguments, isNull);
    });
  });
}
