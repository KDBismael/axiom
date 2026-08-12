import 'package:axiom/core/routes/app_routes.dart';
import 'package:axiom/features/notifications/services/notification_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes every contextual notification family', () {
    expect(
      notificationTarget('validation_requested', {'evidenceId': 'e-1'}).route,
      AppRoutes.validationDetail,
    );
    expect(
      notificationTarget('quest_completed', {'questId': 'q-1'}).route,
      AppRoutes.questDetail,
    );
    expect(
      notificationTarget('ally_request_received', {}).route,
      AppRoutes.inviteFriends,
    );
    expect(
      notificationTarget('quest_ally_invite_received', {
        'questId': 'q-1',
      }).route,
      AppRoutes.questAllyInvitation,
    );
    expect(
      notificationTarget('quest_deletion_requested', {
        'questId': 'q-1',
        'requestId': 'r-1',
      }).route,
      AppRoutes.questDeletionVote,
    );
  });

  test('malformed and unknown payloads fall back to notifications', () {
    expect(
      notificationTarget('quest_completed', {}).route,
      AppRoutes.notifications,
    );
    expect(
      notificationTarget('future_type', {}).route,
      AppRoutes.notifications,
    );
  });
}
