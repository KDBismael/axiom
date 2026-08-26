import 'dart:async';
import 'package:get/get.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../models/stake_transaction.dart';
import '../repositories/payment_repository.dart';
import '../services/url_opener.dart';

/// Data needed to reuse this controller's flow for topping up (or starting)
/// a stake on a quest that's already active — as opposed to the default
/// flow, which pays the stake decided at creation on a `pending_payment`
/// quest and derives the amount server-side.
class StakeTopUp {
  const StakeTopUp({required this.amountXof, this.fundsDistribution});

  final double amountXof;
  final FundsDistribution? fundsDistribution;
}

/// Drives the Wave sandbox stake-payment flow for one already-created
/// `pending_payment` quest: initiates the payment, opens the returned Wave
/// checkout URL, then polls the quest (there's no success_url/error_url
/// wired on the backend, so the app can't rely on a deep-link redirect)
/// until it leaves `pending_payment` or a timeout is reached. The quest
/// already exists before this screen loads, so a failed, cancelled, or
/// timed-out attempt never loses it — [pay] can simply be called again to
/// retry against the same quest.
class QuestPaymentController extends GetxController {
  QuestPaymentController(
    this._repository,
    this._questList,
    this._urlOpener,
    this.questId, {
    this.topUp,
    Duration pollInterval = const Duration(seconds: 3),
    int maxPollAttempts = 40,
  }) : _pollInterval = pollInterval,
       _maxPollAttempts = maxPollAttempts;

  final PaymentRepository _repository;
  final QuestListController _questList;
  final UrlOpener _urlOpener;
  final String questId;
  final StakeTopUp? topUp;
  final Duration _pollInterval;
  final int _maxPollAttempts;

  final transaction = Rxn<StakeTransaction>();
  final isLoading = false.obs;
  final isPolling = false.obs;
  final paymentSucceeded = false.obs;
  final paymentFailed = false.obs;
  final paymentTimedOut = false.obs;
  final errorMessage = RxnString();

  static const _terminalFailureStatuses = {'failed', 'cancelled', 'expired'};

  Timer? _pollTimer;
  int _pollAttempts = 0;

  Future<void> pay({String? phoneNumber}) async {
    isLoading.value = true;
    errorMessage.value = null;
    paymentSucceeded.value = false;
    paymentFailed.value = false;
    paymentTimedOut.value = false;
    try {
      final result = await _repository.initiateStakePayment(
        questId,
        phoneNumber: phoneNumber,
        additionalAmountXof: topUp?.amountXof,
        fundsDistribution: topUp?.fundsDistribution,
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
    final refreshed = await _refreshTransaction();
    if (refreshed != null && _terminalFailureStatuses.contains(refreshed.status)) {
      paymentFailed.value = true;
      stopPolling();
      return;
    }
    final succeeded = topUp != null
        ? refreshed?.status == 'completed'
        : _questActive();
    if (succeeded) {
      paymentSucceeded.value = true;
      stopPolling();
      return;
    }
    if (_pollAttempts >= _maxPollAttempts) {
      paymentTimedOut.value = true;
      stopPolling();
    }
  }

  bool _questActive() =>
      _questList.findById(questId)?.status == QuestStatus.active;

  /// Re-fetches the transaction so both flows can detect a terminal outcome
  /// (success for a top-up, or failure for either flow) as soon as it's
  /// recorded, rather than only inferring it from the quest's own status. A
  /// transient network failure here just means "not yet known" — the next
  /// tick retries rather than surfacing an error mid-poll.
  Future<StakeTransaction?> _refreshTransaction() async {
    final current = transaction.value;
    if (current == null) return null;
    try {
      final refreshed = await _repository.getTransaction(
        current.transactionId,
      );
      transaction.value = refreshed;
      return refreshed;
    } on PaymentException {
      return null;
    }
  }

  /// Re-checks payment status when the app returns to the foreground —
  /// covers the case where the user completed the Wave checkout while the
  /// app was backgrounded and missed the in-app polling window.
  Future<void> onAppResumed() async {
    if (paymentSucceeded.value || paymentFailed.value) return;
    await checkNow();
    if (!paymentSucceeded.value && !paymentFailed.value && !isPolling.value) {
      _startPolling();
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
