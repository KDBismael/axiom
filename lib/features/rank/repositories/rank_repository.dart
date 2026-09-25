import '../../../core/api/api_client.dart';
import '../models/leaderboard_entry.dart';
import '../models/rank_summary.dart';
import '../models/trophy_item.dart';

class RankException implements Exception {
  RankException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RankRepository {
  RankRepository(this._client);

  final ApiClient _client;

  Future<RankSummary> fetchRank() async {
    final response = await _client.get('/me/rank');
    if (!response.isOk || response.body == null) {
      throw RankException(_extractMessage(response.body));
    }
    return RankSummary.fromJson(response.body as Map<String, dynamic>);
  }

  Future<List<TrophyItem>> fetchTrophies() async {
    final response = await _client.get('/me/trophies');
    if (!response.isOk || response.body == null) {
      throw RankException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list
        .map((e) => TrophyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard() async {
    final response = await _client.get('/allies/leaderboard');
    if (!response.isOk || response.body == null) {
      throw RankException(_extractMessage(response.body));
    }
    final list = response.body as List<dynamic>;
    return list
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
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
