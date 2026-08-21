import 'package:get/get.dart';

import '../../quests/controllers/quest_list_controller.dart';
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
    final id = questId ?? Get.arguments as String;
    Get.lazyPut<QuestPaymentController>(
      () => QuestPaymentController(
        Get.find<PaymentRepository>(),
        Get.find<QuestListController>(),
        Get.find<UrlOpener>(),
        id,
      ),
    );
  }
}
