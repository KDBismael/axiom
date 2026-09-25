import 'package:get/get.dart';
import '../models/leaderboard_entry.dart';
import '../models/rank_summary.dart';
import '../models/trophy_item.dart';
import '../repositories/rank_repository.dart';

/// Loads and holds the current user's points/rank/trophies/leaderboard —
/// shared by the Home dashboard and Profile screens so both read the same
/// live snapshot instead of issuing duplicate requests.
class RankController extends GetxController {
  RankController(this._repository);

  final RankRepository _repository;

  final rank = Rxn<RankSummary>();
  final trophies = <TrophyItem>[].obs;
  final leaderboard = <LeaderboardEntry>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _repository.fetchRank(),
        _repository.fetchTrophies(),
        _repository.fetchLeaderboard(),
      ]);
      rank.value = results[0] as RankSummary;
      trophies.assignAll(results[1] as List<TrophyItem>);
      leaderboard.assignAll(results[2] as List<LeaderboardEntry>);
      errorMessage.value = null;
    } on RankException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
