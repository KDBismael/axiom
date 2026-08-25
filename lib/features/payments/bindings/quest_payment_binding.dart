import 'package:get/get.dart';

import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../controllers/quest_payment_controller.dart';
import '../repositories/payment_repository.dart';
import '../services/url_opener.dart';

class QuestPaymentBinding extends Bindings {
  QuestPaymentBinding({this.questId});

  final String? questId;

  @override
  void dependencies() {
    if (!Get.isRegistered<PaymentRepository>()) {
      Get.lazyPut<PaymentRepository>(() => PaymentRepository(Get.find()));
    }
    if (!Get.isRegistered<UrlOpener>()) {
      Get.lazyPut<UrlOpener>(() => UrlOpener());
    }
    // The initial-payment flow passes just the questId (String). Topping up
    // (or starting) a stake on an already-active quest passes a Map with
    // the amount the user chose and, when the quest had no stake yet, their
    // funds-distribution choice.
    final args = questId ?? Get.arguments;
    final String id;
    StakeTopUp? topUp;
    if (args is Map) {
      id = args['questId'] as String;
      final amount = args['additionalAmountXof'];
      if (amount != null) {
        final distribution = args['fundsDistribution'];
        topUp = StakeTopUp(
          amountXof: (amount as num).toDouble(),
          fundsDistribution: distribution != null
              ? FundsDistribution.fromJson(distribution as String)
              : null,
        );
      }
    } else {
      id = args as String;
    }
    Get.lazyPut<QuestPaymentController>(
      () => QuestPaymentController(
        Get.find<PaymentRepository>(),
        Get.find<QuestListController>(),
        Get.find<UrlOpener>(),
        id,
        topUp: topUp,
      ),
    );
  }
}
