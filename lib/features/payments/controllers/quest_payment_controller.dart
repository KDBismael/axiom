import 'dart:async';
import 'package:get/get.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../models/stake_transaction.dart';
import '../repositories/payment_repository.dart';
import '../services/url_opener.dart';

/// Drives the Wave sandbox stake-payment flow for one quest: initiates the
/// payment, opens the returned Wave checkout URL, then polls the quest
/// (there's no success_url/error_url wired on the backend, so the app can't
/// rely on a deep-link redirect) until it leaves `pending_payment` or a
/// timeout is reached.
class QuestPaymentController extends GetxController {
  QuestPaymentController(
    this._repository,
    this._questList,
    this._urlOpener,
    this.questId, {
    Duration pollInterval = const Duration(seconds: 3),
    int maxPollAttempts = 40,
  })  : _pollInterval = pollInterval,
        _maxPollAttempts = maxPollAttempts;

  final PaymentRepository _repository;
  final QuestListController _questList;
  final UrlOpener _urlOpener;
  final String questId;
  final Duration _pollInterval;
  final int _maxPollAttempts;

  final transaction = Rxn<StakeTransaction>();
  final isLoading = false.obs;
  final isPolling = false.obs;
  final paymentSucceeded = false.obs;
  final paymentTimedOut = false.obs;
  final errorMessage = RxnString();

  Timer? _pollTimer;
  int _pollAttempts = 0;

  Future<void> pay({String? phoneNumber}) async {
    isLoading.value = true;
    errorMessage.value = null;
    paymentSucceeded.value = false;
    paymentTimedOut.value = false;
    try {
      final result = await _repository.initiateStakePayment(
        questId,
        phoneNumber: phoneNumber,
      );
      transaction.value = result;
      await _urlOpener.open(result.paymentUrl ?? '');
      _startPolling();
    } on PaymentException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollAttempts = 0;
    isPolling.value = true;
    _pollTimer = Timer.periodic(_pollInterval, (_) => checkNow());
  }

  /// One polling tick — also callable directly for a manual "Vérifier"
  /// refresh action, and re-used by the periodic timer.
  Future<void> checkNow() async {
    _pollAttempts++;
    await _questList.refreshQuest(questId);
    final quest = _questList.findById(questId);
    if (quest?.status == QuestStatus.active) {
      paymentSucceeded.value = true;
      stopPolling();
      return;
    }
    if (_pollAttempts >= _maxPollAttempts) {
      paymentTimedOut.value = true;
      stopPolling();
    }
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    isPolling.value = false;
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }
}
