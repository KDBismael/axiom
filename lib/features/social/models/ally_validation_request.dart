enum ValidationRequestStatus { pending, approved, rejected }

enum ProofType { photo, text }

class AllyValidationRequest {
  final String id;
  final String friendName;
  final String questTitle;
  final ProofType proofType;
  final String evidence;
  final ValidationRequestStatus status;

  const AllyValidationRequest({
    required this.id,
    required this.friendName,
    required this.questTitle,
    required this.proofType,
    required this.evidence,
    this.status = ValidationRequestStatus.pending,
  });

  AllyValidationRequest copyWith({ValidationRequestStatus? status}) {
    return AllyValidationRequest(
      id: id,
      friendName: friendName,
      questTitle: questTitle,
      proofType: proofType,
      evidence: evidence,
      status: status ?? this.status,
    );
  }
}
