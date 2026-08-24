import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A finished-but-not-yet-submitted focus session, held locally until the
/// user submits the check-in it will ride along on (see
/// `FocusTimerController.finish()`).
class FocusSessionDraft {
  const FocusSessionDraft({required this.startedAt, required this.endedAt});

  final DateTime startedAt;
  final DateTime endedAt;

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
  };

  factory FocusSessionDraft.fromJson(Map<String, dynamic> json) {
    return FocusSessionDraft(
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
    );
  }
}

/// Persists a single pending focus session per quest — set on `finish()`,
/// cleared once the check-in it produces is successfully submitted. Survives
/// an app restart between those two moments (finish/submit are deliberately
/// not the same request; see the focus timer plan).
class FocusSessionDraftStore {
  String _keyFor(String questId) => 'focus_session_draft_$questId';

  Future<void> save(String questId, FocusSessionDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(questId), jsonEncode(draft.toJson()));
  }

  Future<FocusSessionDraft?> read(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(questId));
    if (raw == null) return null;
    return FocusSessionDraft.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> clear(String questId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(questId));
  }
}
