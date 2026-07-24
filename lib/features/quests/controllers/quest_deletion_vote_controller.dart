import 'package:get/get.dart';
import '../models/quest_deletion_request.dart';
import '../repositories/quest_repository.dart';

class QuestDeletionVoteController extends GetxController {
  QuestDeletionVoteController(this._repository, this.questId, this.requestId);

  final QuestRepository _repository;
  final String questId;
  final String requestId;

  final request = Rxn<QuestDeletionRequest>();
  final isLoading = false.obs;
  final isVoting = false.obs;
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
      request.value = await _repository.fetchDeletionRequest(questId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true once the vote is cast (whether the request resolved or is
  /// still awaiting other allies) so the view can pop.
  Future<bool> vote({required bool approve}) async {
    isVoting.value = true;
    errorMessage.value = null;
    try {
      await _repository.voteOnDeletionRequest(questId, requestId, approve: approve);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    } finally {
      isVoting.value = false;
    }
  }
}
