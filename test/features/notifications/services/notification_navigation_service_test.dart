import 'package:axiom/core/routes/app_routes.dart';
import 'package:axiom/features/notifications/services/notification_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new result notifications open the dedicated page; legacy ones keep quest detail',
    () {
      for (final type in ['quest_completed', 'quest_failed']) {
        final target = notificationTarget(type, {
          'questId': 'q-1',
          'resultId': 'r-1',
        });
        expect(target.route, AppRoutes.questResult);
        expect(target.arguments, 'q-1');
        expect(
          notificationTarget(type, {'questId': 'q-1'}).route,
          AppRoutes.questDetail,
        );
        expect(
          notificationTarget(type, {'resultId': 'r-1'}).route,
          AppRoutes.notifications,
        );
      }
    },
  );
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
      notificationTarget('ally_request_received', {'requestId': 'ar-1'}).route,
      AppRoutes.allyRequest,
    );
    expect(
      notificationTarget('ally_removed', {}).route,
      AppRoutes.inviteFriends,
    );
    expect(
      notificationTarget('ally_request_declined', {}).route,
      AppRoutes.inviteFriends,
    );
    expect(
      notificationTarget('quest_ally_invite_received', {
        'questId': 'q-1',
      }).route,
      AppRoutes.questAllyInvitation,
    );
    expect(
      notificationTarget('quest_owner_invite_received', {
        'questId': 'q-1',
      }).route,
      AppRoutes.questOwnerInvitation,
    );
    expect(
      notificationTarget('quest_owner_invite_accepted', {
        'questId': 'q-1',
      }).route,
      AppRoutes.questDetail,
    );
    expect(
      notificationTarget('quest_owner_invite_declined', {
        'questId': 'q-1',
      }).route,
      AppRoutes.questDetail,
    );
    expect(
      notificationTarget('quest_owner_invite_expired', {
        'questId': 'q-1',
      }).route,
      AppRoutes.questDetail,
    );
    expect(
      notificationTarget('quest_deletion_requested', {
        'questId': 'q-1',
        'requestId': 'r-1',
      }).route,
      AppRoutes.questDeletionVote,
    );
    expect(
      notificationTarget('quest_deletion_vote_reminder', {
        'questId': 'q-1',
        'requestId': 'r-1',
      }).route,
      AppRoutes.questDeletionVote,
    );
    expect(
      notificationTarget('payout_rejected', {'questId': 'q-1'}).route,
      AppRoutes.questDetail,
    );
    expect(
      notificationTarget('refund_rejected', {'questId': 'q-1'}).route,
      AppRoutes.questDetail,
    );
  });

  test('malformed and unknown payloads fall back to notifications', () {
    expect(
      notificationTarget('quest_completed', {}).route,
      AppRoutes.notifications,
    );
    expect(
      notificationTarget('ally_request_received', {}).route,
      AppRoutes.notifications,
    );
    expect(
      notificationTarget('future_type', {}).route,
      AppRoutes.notifications,
    );
    expect(
      notificationTarget('quest_owner_invite_received', {}).route,
      AppRoutes.notifications,
    );
  });
}
