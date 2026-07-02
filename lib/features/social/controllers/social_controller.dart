import 'package:get/get.dart';
import '../models/ally_invitation.dart';
import '../models/ally_validation_request.dart';
import '../repositories/social_repository.dart';

class SocialController extends GetxController {
  final SocialRepository _repository = Get.find();

  final invitations = <AllyInvitation>[].obs;
  final validationRequests = <AllyValidationRequest>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInvitations();
    loadValidationRequests();
  }

  Future<void> loadInvitations() async {
    invitations.assignAll(await _repository.fetchInvitations());
  }

  Future<void> loadValidationRequests() async {
    validationRequests.assignAll(await _repository.fetchValidationRequests());
  }

  Future<void> respondToInvitation(String id, {required bool accepted}) async {
    final updated = await _repository.respondToInvitation(id, accepted: accepted);
    final index = invitations.indexWhere((i) => i.id == id);
    if (index != -1) invitations[index] = updated;
  }

  Future<void> respondToValidation(String id, {required bool approved}) async {
    final updated = await _repository.respondToValidation(id, approved: approved);
    final index = validationRequests.indexWhere((v) => v.id == id);
    if (index != -1) validationRequests[index] = updated;
  }

  List<AllyInvitation> get pendingInvitations =>
      invitations.where((i) => i.status == InvitationStatus.pending).toList();

  List<AllyValidationRequest> get pendingValidations => validationRequests
      .where((v) => v.status == ValidationRequestStatus.pending)
      .toList();
}
