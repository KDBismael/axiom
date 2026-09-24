import 'package:get/get.dart';
import '../models/quest_pause_request.dart';
import '../repositories/quest_repository.dart';

/// Drives the "an ally reviews a pause request" screen — mirrors
/// [QuestDeletionVoteController], but a single decision resolves it (first
/// wins) instead of an unanimous tally.
class QuestPauseDecisionController extends GetxController {
  QuestPauseDecisionController(this._repository, this.questId, this.requestId);

  final QuestRepository _repository;
  final String questId;
  final String requestId;

  final request = Rxn<QuestPauseRequest>();
  final isLoading = false.obs;
  final isDeciding = false.obs;
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
      request.value = await _repository.fetchPauseRequest(questId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true once the decision is recorded so the view can pop.
  Future<bool> decide({required bool approve}) async {
    isDeciding.value = true;
    errorMessage.value = null;
    try {
      await _repository.decidePauseRequest(
        questId,
        requestId,
        approve: approve,
      );
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    } finally {
      isDeciding.value = false;
    }
  }
}
