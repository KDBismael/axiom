import 'package:get/get.dart';
import '../models/quest_result.dart';
import '../repositories/quest_repository.dart';

class QuestResultController extends GetxController {
  QuestResultController(this._repository, this.questId);
  final QuestRepository _repository;
  final String questId;
  final result = Rxn<QuestResult>();
  final isLoading = false.obs;
  final errorMessage = RxnString();
  bool get isUnavailable =>
      !isLoading.value && errorMessage.value == null && result.value == null;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    result.value = null;
    try {
      result.value = await _repository.fetchResult(questId);
    } on QuestException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'Impossible de charger le bilan. Réessaie.';
    } finally {
      isLoading.value = false;
    }
  }
}
