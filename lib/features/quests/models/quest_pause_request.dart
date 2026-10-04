enum QuestPauseRequestStatus {
  pending,
  approved,
  rejected;

  factory QuestPauseRequestStatus.fromJson(String value) =>
      QuestPauseRequestStatus.values.firstWhere((v) => v.name == value);
}

/// A pause ("sick mode") request for a quest — needs approval from ONE
/// accepted ally (first decision wins), unlike a deletion request's
/// unanimous vote, since a pause is temporary and reversible.
/// `GET /quests/:id/pause-request`.
class QuestPauseRequest {
  const QuestPauseRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    this.description,
    this.fileIds = const [],
    this.textContent,
    this.comment,
    this.decidedAt,
    this.resumedAt,
  });

  final String id;
  final QuestPauseRequestStatus status;
  final DateTime createdAt;

  /// The reason given for the pause (e.g. "Grippe"), if any.
  final String? description;
  final List<String> fileIds;
  final String? textContent;

  String? get reason => description ?? textContent;

  /// The deciding ally's comment, if any.
  final String? comment;
  final DateTime? decidedAt;

  /// Set once the owner ends the pause this request activated.
  final DateTime? resumedAt;

  bool get isActive =>
      status == QuestPauseRequestStatus.approved && resumedAt == null;

  factory QuestPauseRequest.fromJson(Map<String, dynamic> json) {
    return QuestPauseRequest(
      id: json['id'] as String,
      status: QuestPauseRequestStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      fileIds: (json['fileIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      textContent: json['textContent'] as String?,
      comment: json['comment'] as String?,
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
      resumedAt: json['resumedAt'] == null
          ? null
          : DateTime.parse(json['resumedAt'] as String),
    );
  }
}
