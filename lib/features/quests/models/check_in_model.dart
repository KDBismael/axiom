enum ProofType {
  photo,
  video,
  text,
  file;

  factory ProofType.fromJson(String value) =>
      ProofType.values.firstWhere((v) => v.name == value);

  String toJson() => name;
}

enum EvidenceStatus {
  pending,
  approved,
  rejected;

  factory EvidenceStatus.fromJson(String value) =>
      EvidenceStatus.values.firstWhere((v) => v.name == value);
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.questId,
    required this.date,
    this.evidence = const [],
  });

  final String id;
  final String questId;
  final DateTime date;
  final List<Evidence> evidence;

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['evidence'] as List<dynamic>?;
    return CheckIn(
      id: json['id'] as String,
      questId: json['questId'] as String,
      date: DateTime.parse(json['date'] as String),
      evidence: rawEvidence == null
          ? const []
          : rawEvidence.map((e) => Evidence.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class Evidence {
  const Evidence({
    required this.id,
    required this.proofType,
    required this.status,
    this.fileId,
    this.fileIds = const [],
    this.textContent,
    this.description,
    this.reviewComment,
  });

  final String id;
  final ProofType proofType;
  final String? fileId;

  /// Up to 3 files for a photo proof; single-file video/legacy proofs use
  /// [fileId] instead.
  final List<String> fileIds;
  final String? textContent;
  final String? description;
  final EvidenceStatus status;

  /// The ally's comment left when approving/rejecting this evidence, if any.
  final String? reviewComment;

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: json['id'] as String,
      proofType: ProofType.fromJson(json['proofType'] as String),
      fileId: json['fileId'] as String?,
      fileIds: (json['fileIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      textContent: json['textContent'] as String?,
      description: json['description'] as String?,
      status: EvidenceStatus.fromJson(json['status'] as String),
      reviewComment: json['reviewComment'] as String?,
    );
  }
}

/// Response envelope for `POST /quests/:id/check-ins`.
class CheckInResult {
  const CheckInResult({
    required this.checkIn,
    required this.streakDays,
    required this.progress,
    required this.currentPeriodCount,
    required this.targetPerPeriod,
    this.evidence,
  });

  final CheckIn checkIn;
  final int streakDays;
  final double progress;

  /// How many check-ins this period (day/week) has now, including this one.
  final int currentPeriodCount;

  /// The quest's `targetPerPeriod` at submission time — copied onto the
  /// response so the confirmation screen doesn't need a separate quest fetch.
  final int targetPerPeriod;
  final Evidence? evidence;

  /// `POST /quests/:id/check-ins` returns the check-in row flattened with
  /// `streakDays`/`progress`/`currentPeriodCount`/`targetPerPeriod`/`evidence`
  /// alongside it (not nested under a `checkIn` key) — see
  /// `check-ins.service.ts`'s `{ ...checkIn, streakDays, progress,
  /// currentPeriodCount, targetPerPeriod, evidence }`.
  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    final evidence = json['evidence'] == null
        ? null
        : Evidence.fromJson(json['evidence'] as Map<String, dynamic>);
    return CheckInResult(
      checkIn: CheckIn(
        id: json['id'] as String,
        questId: json['questId'] as String,
        date: DateTime.parse(json['date'] as String),
        evidence: evidence == null ? const [] : [evidence],
      ),
      streakDays: json['streakDays'] as int,
      progress: (json['progress'] as num).toDouble(),
      currentPeriodCount: json['currentPeriodCount'] as int,
      targetPerPeriod: json['targetPerPeriod'] as int,
      evidence: evidence,
    );
  }
}
