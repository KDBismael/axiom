/// A logged focus-timer session, as returned by
/// `GET /quests/:id/focus-sessions`.
class FocusSession {
  const FocusSession({
    required this.id,
    required this.questId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
  });

  final String id;
  final String questId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      questId: json['questId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}

/// `GET /quests/:id/focus-sessions` response: every session for the quest,
/// newest first, plus today's total minutes (informational only — there is
/// no enforced per-quest minute goal).
class FocusSessionHistory {
  const FocusSessionHistory({required this.sessions, required this.todayMinutes});

  final List<FocusSession> sessions;
  final int todayMinutes;

  factory FocusSessionHistory.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'] as List<dynamic>? ?? const [];
    return FocusSessionHistory(
      sessions: rawSessions
          .map((s) => FocusSession.fromJson(s as Map<String, dynamic>))
          .toList(),
      todayMinutes: json['todayMinutes'] as int? ?? 0,
    );
  }
}
