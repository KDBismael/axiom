import 'package:get/get.dart';
import '../models/quest_group_invitation.dart';
import '../repositories/quest_repository.dart';

/// Drives the "you've been invited to a collective quest" screen —
/// deliberately a sibling of [QuestOwnerInvitationController], not a reuse
/// of it: accepting here makes the invitee a full CO-PARTICIPANT (their own
/// Quest, identical rules) and a validator for every other member, not the
/// sole owner.
class QuestGroupInvitationController extends GetxController {
  QuestGroupInvitationController(this._repository, this.groupId);

  final QuestRepository _repository;
  final String groupId;

  final invitation = Rxn<QuestGroupInvitation>();
  final isLoading = false.obs;
  final isResponding = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      invitation.value = await _repository.fetchGroupInvitation(groupId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true on success so the view can pop.
  Future<bool> respond({required bool accept}) async {
    isResponding.value = true;
    errorMessage.value = null;
    try {
      await _repository.respondToGroupInvitation(groupId, accept: accept);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    } finally {
      isResponding.value = false;
    }
  }
}
