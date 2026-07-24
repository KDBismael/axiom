import 'package:get/get.dart';
import '../models/quest_ally_invitation.dart';
import '../repositories/quest_repository.dart';

class QuestAllyInvitationController extends GetxController {
  QuestAllyInvitationController(this._repository, this.questId);

  final QuestRepository _repository;
  final String questId;

  final invitation = Rxn<QuestAllyInvitation>();
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
      invitation.value = await _repository.fetchAllyInvitation(questId);
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
      await _repository.respondToAllyInvitation(questId, accept: accept);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    } finally {
      isResponding.value = false;
    }
  }
}
