import 'package:get/get.dart';
import '../models/check_in_model.dart';
import '../models/focus_session_model.dart';
import '../models/quest_ally_invitation_summary.dart';
import '../models/quest_deletion_request.dart';
import '../models/quest_group_invitation_summary.dart';
import '../models/quest_group_progress.dart';
import '../models/quest_model.dart';
import '../models/quest_owner_invitation_summary.dart';
import '../models/quest_pause_request.dart';
import '../models/quest_pause_request_summary.dart';
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

  /// Quests the current user has been offered ownership of (sponsor
  /// quests) — same discoverability rationale as [pendingAllyInvitations].
  final pendingOwnerInvitations = <QuestOwnerInvitationSummary>[].obs;

  /// Collective quests the current user has been invited to join — same
  /// discoverability rationale as [pendingAllyInvitations].
  final pendingGroupInvitations = <QuestGroupInvitationSummary>[].obs;

  /// Every member's progress for a collective quest, keyed by groupId —
  /// populated on demand by [loadGroupProgress] (the quest detail screen).
  final groupProgress = <String, QuestGroupProgress?>{}.obs;

  /// The current/most recent pause ("sick mode") request for a quest, keyed
  /// by questId — populated on demand by [loadPauseRequest] (the quest
  /// detail screen).
  final pauseRequests = <String, QuestPauseRequest?>{}.obs;

  /// Pause requests awaiting the current user's decision, across every
  /// quest they're an accepted ally on — same discoverability rationale as
  /// [pendingAllyInvitations].
  final pendingPauseRequests = <QuestPauseRequestSummary>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadQuests();
    loadPendingAllyInvitations();
    loadPendingOwnerInvitations();
    loadPendingGroupInvitations();
    loadPendingPauseRequests();
  }

  Future<void> loadPendingAllyInvitations() async {
    try {
      pendingAllyInvitations.assignAll(
        await _repository.fetchMyAllyInvitations(),
      );
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> loadPendingOwnerInvitations() async {
    try {
      pendingOwnerInvitations.assignAll(
        await _repository.fetchMyOwnerInvitations(),
      );
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> loadPendingGroupInvitations() async {
    try {
      pendingGroupInvitations.assignAll(
        await _repository.fetchMyGroupInvitations(),
      );
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> loadPendingPauseRequests() async {
    try {
      pendingPauseRequests.assignAll(
        await _repository.fetchMyPauseRequests(),
      );
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> loadQuests() async {
    final showInitialLoader = quests.isEmpty;
    if (showInitialLoader) isLoading.value = true;
    errorMessage.value = null;
    try {
      final data = await _repository.fetchQuests();
      quests.assignAll(data);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    } finally {
      if (showInitialLoader) isLoading.value = false;
    }
  }

  Future<QuestModel?> createQuest(Map<String, dynamic> payload) async {
    errorMessage.value = null;
    try {
      final created = await _repository.createQuest(payload);
      quests.add(created);
      return created;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return null;
    }
  }

  /// Creates a collective quest: the caller's own Quest is created
  /// immediately (unstaked, active); anyone listed joins once they accept
  /// their invitation. See [createQuest] for the solo-quest equivalent.
  Future<QuestModel?> createQuestGroup(Map<String, dynamic> payload) async {
    errorMessage.value = null;
    try {
      final created = await _repository.createQuestGroup(payload);
      quests.add(created);
      return created;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return null;
    }
  }

  /// Fetches every member's progress for a collective quest and caches it
  /// under its groupId (the quest detail screen reads this reactively).
  Future<void> loadGroupProgress(String groupId) async {
    try {
      groupProgress[groupId] = await _repository.fetchGroupProgress(groupId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  /// Invites more people to an already-created collective quest. Returns
  /// true on success, after which the group's progress view is refreshed to
  /// reflect the change is on its way (new invitations don't appear there
  /// until accepted).
  Future<bool> inviteGroupMembers(
    String groupId,
    List<String> memberUserIds,
  ) async {
    errorMessage.value = null;
    try {
      await _repository.inviteGroupMembers(groupId, memberUserIds);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    }
  }

  /// Fetches the current/most recent pause request for a quest and caches
  /// it under its questId (the quest detail screen reads this reactively).
  Future<void> loadPauseRequest(String questId) async {
    try {
      pauseRequests[questId] = await _repository.fetchPauseRequest(questId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    }
  }

  /// Requests a pause ("sick mode") with a text reason as proof. Auto-
  /// activates immediately if the quest has no accepted allies; otherwise
  /// waits for one of them to approve it. Refreshes the quest either way so
  /// its status reflects the outcome.
  Future<bool> requestPause(String questId, {required String reason}) async {
    errorMessage.value = null;
    try {
      pauseRequests[questId] = await _repository.requestPause(
        questId,
        proofType: ProofType.text,
        textContent: reason,
      );
      await refreshQuest(questId);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    }
  }

  /// An accepted ally approves/rejects a pending pause request. Returns
  /// true on success, after which the caller's list of pending decisions is
  /// refreshed.
  Future<bool> decidePauseRequest(
    String questId,
    String requestId, {
    required bool approve,
    String? comment,
  }) async {
    errorMessage.value = null;
    try {
      await _repository.decidePauseRequest(
        questId,
        requestId,
        approve: approve,
        comment: comment,
      );
      await loadPendingPauseRequests();
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    }
  }

  /// Ends a pause: the deadline is pushed back by however long the quest
  /// was paused, and it returns to active. No ally approval needed.
  Future<bool> resumeQuest(String questId) async {
    errorMessage.value = null;
    try {
      final updated = await _repository.resumeQuest(questId);
      final index = quests.indexWhere((q) => q.id == questId);
      if (index != -1) quests[index] = updated;
      pauseRequests.remove(questId);
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
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
    List<String>? fileIds,
    String? textContent,
    String? description,
    DateTime? focusStartedAt,
    DateTime? focusEndedAt,
  }) async {
    errorMessage.value = null;
    try {
      final result = await _repository.checkIn(
        questId,
        date: date,
        proofType: proofType,
        fileId: fileId,
        fileIds: fileIds,
        textContent: textContent,
        description: description,
        focusStartedAt: focusStartedAt,
        focusEndedAt: focusEndedAt,
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

  Future<List<CheckIn>> fetchCheckIns(String questId) =>
      _repository.fetchCheckIns(questId);

  Future<FocusSessionHistory> fetchFocusSessions(String questId) =>
      _repository.fetchFocusSessions(questId);

  Future<String> uploadEvidenceFile(PickedEvidence picked) =>
      _repository.uploadEvidenceFile(picked);

  Future<Evidence?> resubmitProof(
    String questId,
    String checkInId, {
    required ProofType proofType,
    String? fileId,
    List<String>? fileIds,
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
        fileIds: fileIds,
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

  /// Money currently at stake — only quests still active count; a
  /// finished quest's stake has already been refunded/paid out, so
  /// summing over the full [quests] history (including it) would inflate
  /// this past what's actually at risk right now.
  double get totalStakeAmount =>
      activeQuests.fold(0, (sum, quest) => sum + (quest.stakeAmountXof ?? 0));

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
      final updated = await _repository.updateQuest(questId, {
        'description': description,
      });
      final index = quests.indexWhere((q) => q.id == questId);
      if (index != -1) quests[index] = updated;
      return true;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return false;
    }
  }

  /// Quests still actionable from the dashboard — ongoing, awaiting stake
  /// payment, or (for a sponsor) awaiting the invitee's acceptance.
  List<QuestModel> get activeQuests => quests
      .where(
        (q) =>
            q.status == QuestStatus.active ||
            q.status == QuestStatus.paused ||
            q.status == QuestStatus.pendingPayment ||
            q.status == QuestStatus.pendingOwnerAcceptance,
      )
      .toList();

  /// Finished quests — shown in the History tab.
  List<QuestModel> get historyQuests =>
      quests.where((q) => q.isFinished).toList();

  /// The pending deletion request for a quest, if any — populated by
  /// [requestDeletion]/[loadDeletionRequest].
  final deletionRequests = <String, QuestDeletionRequest?>{}.obs;

  Future<void> loadDeletionRequest(String questId) async {
    try {
      deletionRequests[questId] = await _repository.fetchDeletionRequest(
        questId,
      );
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
      await _repository.voteOnDeletionRequest(
        questId,
        requestId,
        approve: approve,
      );
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
