import 'package:get/get.dart';
import '../models/check_in_model.dart';
import '../models/quest_ally_invitation_summary.dart';
import '../models/quest_deletion_request.dart';
import '../models/quest_model.dart';
import '../repositories/quest_repository.dart';
import '../services/evidence_picker_service.dart';

class QuestListController extends GetxController {
  QuestListController(this._repository);

  final QuestRepository _repository;

  final quests = <QuestModel>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  /// Quests the current user has been invited to ally on — surfaced on the
  /// dashboard so they're discoverable even if the originating notification
  /// was dismissed.
  final pendingAllyInvitations = <QuestAllyInvitationSummary>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadQuests();
    loadPendingAllyInvitations();
  }

  Future<void> loadPendingAllyInvitations() async {
    try {
      pendingAllyInvitations.assignAll(await _repository.fetchMyAllyInvitations());
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> loadQuests() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final data = await _repository.fetchQuests();
      quests.assignAll(data);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createQuest(Map<String, dynamic> payload) async {
    errorMessage.value = null;
    try {
      final created = await _repository.createQuest(payload);
      quests.add(created);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  /// Submits a check-in (optionally with proof); on success, refreshes the
  /// quest in the local list with its updated progress/streak. Returns the
  /// check-in result so the caller can inspect the created evidence, or
  /// null on failure (see [errorMessage] for the backend's French message).
  Future<CheckInResult?> checkIn(
    String questId, {
    DateTime? date,
    ProofType? proofType,
    String? fileId,
    String? textContent,
    String? description,
  }) async {
    errorMessage.value = null;
    try {
      final result = await _repository.checkIn(
        questId,
        date: date,
        proofType: proofType,
        fileId: fileId,
        textContent: textContent,
        description: description,
      );
      final refreshed = await _repository.fetchQuest(questId);
      final index = quests.indexWhere((q) => q.id == questId);
      if (index != -1) quests[index] = refreshed;
      return result;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return null;
    }
  }

  Future<List<CheckIn>> fetchCheckIns(String questId) => _repository.fetchCheckIns(questId);

  Future<String> uploadEvidenceFile(PickedEvidence picked) =>
      _repository.uploadEvidenceFile(picked);

  Future<Evidence?> resubmitProof(
    String questId,
    String checkInId, {
    required ProofType proofType,
    String? fileId,
    String? textContent,
    String? description,
  }) async {
    errorMessage.value = null;
    try {
      return await _repository.resubmitProof(
        questId,
        checkInId,
        proofType: proofType,
        fileId: fileId,
        textContent: textContent,
        description: description,
      );
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return null;
    }
  }

  QuestModel? findById(String id) {
    try {
      return quests.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalStakeAmount =>
      quests.fold(0, (sum, quest) => sum + (quest.stakeAmountXof ?? 0));

  String get riskLevel {
    if (totalStakeAmount >= 500) return 'ÉLEVÉ';
    if (totalStakeAmount >= 200) return 'MODÉRÉ';
    return 'FAIBLE';
  }

  /// Re-fetches a single quest (the list endpoint omits `allies`) and
  /// replaces it in place.
  Future<void> refreshQuest(String questId) async {
    try {
      final refreshed = await _repository.fetchQuest(questId);
      final index = quests.indexWhere((q) => q.id == questId);
      if (index != -1) {
        quests[index] = refreshed;
      } else {
        quests.add(refreshed);
      }
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<bool> updateDescription(String questId, String description) async {
    errorMessage.value = null;
    try {
      final updated = await _repository.updateQuest(questId, {'description': description});
      final index = quests.indexWhere((q) => q.id == questId);
      if (index != -1) quests[index] = updated;
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    }
  }

  /// Quests still actionable from the dashboard — ongoing or awaiting stake
  /// payment before they start.
  List<QuestModel> get activeQuests => quests
      .where((q) => q.status == QuestStatus.active || q.status == QuestStatus.pendingPayment)
      .toList();

  /// Finished quests — shown in the History tab.
  List<QuestModel> get historyQuests => quests.where((q) => q.isFinished).toList();

  /// The pending deletion request for a quest, if any — populated by
  /// [requestDeletion]/[loadDeletionRequest].
  final deletionRequests = <String, QuestDeletionRequest?>{}.obs;

  Future<void> loadDeletionRequest(String questId) async {
    try {
      deletionRequests[questId] = await _repository.fetchDeletionRequest(questId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<QuestDeletionOutcome?> requestDeletion(String questId) async {
    errorMessage.value = null;
    try {
      final outcome = await _repository.requestDeletion(questId);
      if (outcome.deleted || outcome.cancelled) {
        quests.removeWhere((q) => q.id == questId);
        deletionRequests.remove(questId);
      } else if (outcome.pending) {
        await loadDeletionRequest(questId);
      }
      return outcome;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return null;
    }
  }

  Future<void> voteOnDeletionRequest(
    String questId,
    String requestId, {
    required bool approve,
  }) async {
    errorMessage.value = null;
    try {
      await _repository.voteOnDeletionRequest(questId, requestId, approve: approve);
      await loadDeletionRequest(questId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  /// Invites more allies onto an already-created quest. Returns true on
  /// success, after which the quest is refreshed to show the new pending
  /// invites.
  Future<bool> inviteAllies(String questId, List<String> allyUserIds) async {
    errorMessage.value = null;
    try {
      await _repository.inviteAllies(questId, allyUserIds);
      await refreshQuest(questId);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    }
  }
}
