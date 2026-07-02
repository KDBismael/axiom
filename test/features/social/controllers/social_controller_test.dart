import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:axiom/features/social/controllers/social_controller.dart';
import 'package:axiom/features/social/models/ally_invitation.dart';
import 'package:axiom/features/social/models/ally_validation_request.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';

void main() {
  setUp(() {
    Get.put<SocialRepository>(SocialRepository());
  });

  tearDown(Get.reset);

  group('SocialController', () {
    test('loads seeded pending invitations and validation requests on init', () async {
      final controller = SocialController();
      await Future.wait([controller.loadInvitations(), controller.loadValidationRequests()]);

      expect(controller.pendingInvitations, isNotEmpty);
      expect(controller.pendingValidations, isNotEmpty);
      expect(
        controller.pendingInvitations.every((i) => i.status == InvitationStatus.pending),
        isTrue,
      );
    });

    test('accepting an invitation removes it from pendingInvitations', () async {
      final controller = SocialController();
      await controller.loadInvitations();
      final id = controller.invitations.first.id;

      await controller.respondToInvitation(id, accepted: true);

      expect(controller.pendingInvitations.any((i) => i.id == id), isFalse);
      final updated = controller.invitations.firstWhere((i) => i.id == id);
      expect(updated.status, InvitationStatus.accepted);
    });

    test('declining an invitation removes it from pendingInvitations', () async {
      final controller = SocialController();
      await controller.loadInvitations();
      final id = controller.invitations.first.id;

      await controller.respondToInvitation(id, accepted: false);

      expect(controller.pendingInvitations.any((i) => i.id == id), isFalse);
      final updated = controller.invitations.firstWhere((i) => i.id == id);
      expect(updated.status, InvitationStatus.declined);
    });

    test('approving a validation request removes it from pendingValidations', () async {
      final controller = SocialController();
      await controller.loadValidationRequests();
      final id = controller.validationRequests.first.id;

      await controller.respondToValidation(id, approved: true);

      expect(controller.pendingValidations.any((v) => v.id == id), isFalse);
      final updated = controller.validationRequests.firstWhere((v) => v.id == id);
      expect(updated.status, ValidationRequestStatus.approved);
    });

    test('rejecting a validation request removes it from pendingValidations', () async {
      final controller = SocialController();
      await controller.loadValidationRequests();
      final id = controller.validationRequests.first.id;

      await controller.respondToValidation(id, approved: false);

      expect(controller.pendingValidations.any((v) => v.id == id), isFalse);
      final updated = controller.validationRequests.firstWhere((v) => v.id == id);
      expect(updated.status, ValidationRequestStatus.rejected);
    });
  });
}
