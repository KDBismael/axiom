import '../../quests/models/check_in_model.dart' show ProofType;

enum ValidationDecisionStatus {
  pending,
  approved,
  rejected,
  cancelled;

  factory ValidationDecisionStatus.fromJson(String value) =>
      ValidationDecisionStatus.values.firstWhere((v) => v.name == value);
}

/// A validation request I (the ally) am asked to judge — `GET /validations`.
class AllyValidationRequest {
  const AllyValidationRequest({
    required this.id,
    required this.questId,
    required this.questTitle,
    required this.evidenceId,
    required this.proofType,
    required this.status,
    this.textContent,
    this.fileId,
  });

  final String id;
  final String questId;
  final String questTitle;
  final String evidenceId;
  final ProofType proofType;
  final String? textContent;
  final String? fileId;
  final ValidationDecisionStatus status;

  /// `GET /validations` returns the request row flattened together with a
  /// nested `evidence` object (which itself nests `quest: { title }`) —
  /// see `validations.service.ts`'s `{ ...request, evidence }`.
  factory AllyValidationRequest.fromJson(Map<String, dynamic> json) {
    final evidence = json['evidence'] as Map<String, dynamic>;
    final quest = evidence['quest'] as Map<String, dynamic>?;
    return AllyValidationRequest(
      id: json['id'] as String,
      questId: evidence['questId'] as String,
      questTitle: quest?['title'] as String? ?? '',
      evidenceId: json['evidenceId'] as String,
      proofType: ProofType.fromJson(evidence['proofType'] as String),
      textContent: evidence['textContent'] as String?,
      fileId: evidence['fileId'] as String?,
      status: ValidationDecisionStatus.fromJson(json['status'] as String),
    );
  }
}
