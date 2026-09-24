import 'package:get/get.dart';
import '../../../core/api/api_client.dart';
import '../models/check_in_model.dart';
import '../models/focus_session_model.dart';
import '../models/quest_ally_invitation.dart';
import '../models/quest_ally_invitation_summary.dart';
import '../models/quest_deletion_request.dart';
import '../models/quest_group_invitation.dart';
import '../models/quest_group_invitation_summary.dart';
import '../models/quest_group_progress.dart';
import '../models/quest_model.dart';
import '../models/quest_owner_invitation.dart';
import '../models/quest_owner_invitation_summary.dart';
import '../models/quest_pause_request.dart';
import '../models/quest_pause_request_summary.dart';
import '../services/evidence_picker_service.dart';

/// Thrown when the backend rejects a quest/check-in request; [message] is
/// the backend's own French-language message, ready to show directly in
/// the UI.
class QuestException implements Exception {
  QuestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuestRepository {
  QuestRepository(this._client);

  final ApiClient _client;

  Future<List<QuestModel>> fetchQuests() async {
    final response = await _client.get('/quests');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => QuestModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<QuestModel> fetchQuest(String id) async {
    final response = await _client.get('/quests/$id');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestModel.fromJson(response.body as Map<String, dynamic>);
  }

  Future<QuestModel> createQuest(Map<String, dynamic> payload) async {
    final response = await _client.post('/quests', payload);
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestModel.fromJson(response.body as Map<String, dynamic>);
  }

  Future<QuestModel> updateQuest(String id, Map<String, dynamic> changes) async {
    final response = await _client.patch('/quests/$id', changes);
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestModel.fromJson(response.body as Map<String, dynamic>);
  }

  Future<QuestDeletionOutcome> requestDeletion(String questId) async {
    final response = await _client.post('/quests/$questId/delete-request', {});
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestDeletionOutcome.fromJson(response.body as Map<String, dynamic>);
  }

  Future<QuestDeletionRequest?> fetchDeletionRequest(String questId) async {
    final response = await _client.get('/quests/$questId/delete-request');
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
    if (response.body == null) return null;
    return QuestDeletionRequest.fromJson(response.body as Map<String, dynamic>);
  }

  Future<void> voteOnDeletionRequest(
    String questId,
    String requestId, {
    required bool approve,
  }) async {
    final response = await _client.post(
      '/quests/$questId/delete-request/$requestId/votes',
      {'decision': approve ? 'approve' : 'reject'},
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<void> inviteAllies(String questId, List<String> allyUserIds) async {
    final response = await _client.post(
      '/quests/$questId/allies',
      {'allyUserIds': allyUserIds},
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<List<QuestAllyInvitationSummary>> fetchMyAllyInvitations() async {
    final response = await _client.get('/quests/ally-invitations');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list
        .map((e) => QuestAllyInvitationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QuestAllyInvitation> fetchAllyInvitation(String questId) async {
    final response = await _client.get('/quests/$questId/ally-invitation');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestAllyInvitation.fromJson(response.body as Map<String, dynamic>);
  }

  Future<void> respondToAllyInvitation(
    String questId, {
    required bool accept,
  }) async {
    final response = await _client.post(
      '/quests/$questId/ally-invitation/respond',
      {'decision': accept ? 'accept' : 'decline'},
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<List<QuestOwnerInvitationSummary>> fetchMyOwnerInvitations() async {
    final response = await _client.get('/quests/owner-invitations');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list
        .map(
          (e) => QuestOwnerInvitationSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<QuestOwnerInvitation> fetchOwnerInvitation(String questId) async {
    final response = await _client.get('/quests/$questId/owner-invitation');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestOwnerInvitation.fromJson(response.body as Map<String, dynamic>);
  }

  Future<void> respondToOwnerInvitation(
    String questId, {
    required bool accept,
  }) async {
    final response = await _client.post(
      '/quests/$questId/owner-invitation/respond',
      {'decision': accept ? 'accept' : 'decline'},
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<QuestModel> createQuestGroup(Map<String, dynamic> payload) async {
    final response = await _client.post('/quests/groups', payload);
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestModel.fromJson(response.body as Map<String, dynamic>);
  }

  Future<List<QuestGroupInvitationSummary>> fetchMyGroupInvitations() async {
    final response = await _client.get('/quests/groups/invitations');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list
        .map(
          (e) => QuestGroupInvitationSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<QuestGroupInvitation> fetchGroupInvitation(String groupId) async {
    final response = await _client.get('/quests/groups/$groupId/invitation');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestGroupInvitation.fromJson(response.body as Map<String, dynamic>);
  }

  Future<void> respondToGroupInvitation(
    String groupId, {
    required bool accept,
  }) async {
    final response = await _client.post(
      '/quests/groups/$groupId/invitation/respond',
      {'decision': accept ? 'accept' : 'decline'},
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<void> inviteGroupMembers(
    String groupId,
    List<String> memberUserIds,
  ) async {
    final response = await _client.post(
      '/quests/groups/$groupId/members',
      {'memberUserIds': memberUserIds},
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<QuestGroupProgress> fetchGroupProgress(String groupId) async {
    final response = await _client.get('/quests/groups/$groupId/progress');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestGroupProgress.fromJson(response.body as Map<String, dynamic>);
  }

  Future<QuestPauseRequest> requestPause(
    String questId, {
    required ProofType proofType,
    String? fileId,
    List<String>? fileIds,
    String? textContent,
    String? description,
  }) async {
    final response = await _client.post('/quests/$questId/pause-request', {
      'proofType': proofType.toJson(),
      if (fileId != null) 'fileId': fileId,
      if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
      if (textContent != null) 'textContent': textContent,
      if (description != null) 'description': description,
    });
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestPauseRequest.fromJson(response.body as Map<String, dynamic>);
  }

  Future<QuestPauseRequest?> fetchPauseRequest(String questId) async {
    final response = await _client.get('/quests/$questId/pause-request');
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
    if (response.body == null) return null;
    return QuestPauseRequest.fromJson(response.body as Map<String, dynamic>);
  }

  Future<List<QuestPauseRequestSummary>> fetchMyPauseRequests() async {
    final response = await _client.get('/quests/pause-requests');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list
        .map(
          (e) => QuestPauseRequestSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> decidePauseRequest(
    String questId,
    String requestId, {
    required bool approve,
    String? comment,
  }) async {
    final response = await _client.post(
      '/quests/$questId/pause-request/$requestId/decide',
      {
        'decision': approve ? 'approve' : 'reject',
        if (comment != null) 'comment': comment,
      },
    );
    if (!response.isOk) {
      throw QuestException(_extractMessage(response.body));
    }
  }

  Future<QuestModel> resumeQuest(String questId) async {
    final response = await _client.post('/quests/$questId/resume', {});
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return QuestModel.fromJson(response.body as Map<String, dynamic>);
  }

  Future<CheckInResult> checkIn(
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
    final response = await _client.post('/quests/$questId/check-ins', {
      if (date != null) 'date': date.toIso8601String(),
      if (proofType != null) 'proofType': proofType.toJson(),
      if (fileId != null) 'fileId': fileId,
      if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
      if (textContent != null) 'textContent': textContent,
      if (description != null) 'description': description,
      if (focusStartedAt != null)
        'focusStartedAt': focusStartedAt.toIso8601String(),
      if (focusEndedAt != null) 'focusEndedAt': focusEndedAt.toIso8601String(),
    });
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return CheckInResult.fromJson(response.body as Map<String, dynamic>);
  }

  Future<List<CheckIn>> fetchCheckIns(String questId) async {
    final response = await _client.get('/quests/$questId/check-ins');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => CheckIn.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FocusSessionHistory> fetchFocusSessions(String questId) async {
    final response = await _client.get('/quests/$questId/focus-sessions');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return FocusSessionHistory.fromJson(response.body as Map<String, dynamic>);
  }

  Future<Evidence> resubmitProof(
    String questId,
    String checkInId, {
    required ProofType proofType,
    String? fileId,
    List<String>? fileIds,
    String? textContent,
    String? description,
  }) async {
    final response = await _client.post('/quests/$questId/check-ins/$checkInId/proofs', {
      'proofType': proofType.toJson(),
      if (fileId != null) 'fileId': fileId,
      if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
      if (textContent != null) 'textContent': textContent,
      if (description != null) 'description': description,
    });
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    return Evidence.fromJson(response.body as Map<String, dynamic>);
  }

  Future<List<Evidence>> fetchEvidence(String questId) async {
    final response = await _client.get('/quests/$questId/evidence');
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list.map((e) => Evidence.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> uploadEvidenceFile(PickedEvidence picked) async {
    final formData = FormData({
      'file': MultipartFile(
        picked.bytes,
        filename: picked.filename,
        contentType: picked.mimeType,
      ),
      'purpose': 'quest_evidence',
    });
    final response = await _client.post('/files/upload', formData);
    if (!response.isOk || response.body == null) {
      throw QuestException(_extractMessage(response.body));
    }
    final json = response.body as Map<String, dynamic>;
    return json['id'] as String;
  }

  String _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is List) return message.join('\n');
      if (message is String) return message;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
