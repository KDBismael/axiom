import 'package:get/get.dart';
import '../models/quest_owner_invitation.dart';
import '../repositories/quest_repository.dart';

/// Drives the "you've been offered a quest" screen — deliberately a sibling
/// of [QuestAllyInvitationController], not a reuse of it: accepting here
/// makes the invitee the quest OWNER (they commit to doing the habit
/// themselves), not an accountability partner.
class QuestOwnerInvitationController extends GetxController {
  QuestOwnerInvitationController(this._repository, this.questId);

  final QuestRepository _repository;
  final String questId;

  final invitation = Rxn<QuestOwnerInvitation>();
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
      invitation.value = await _repository.fetchOwnerInvitation(questId);
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
      await _repository.respondToOwnerInvitation(questId, accept: accept);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    } finally {
      isResponding.value = false;
    }
  }
}
