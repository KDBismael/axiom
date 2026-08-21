import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:axiom/features/payments/bindings/quest_payment_binding.dart';
import 'package:axiom/features/payments/controllers/quest_payment_controller.dart';
import 'package:axiom/features/payments/repositories/payment_repository.dart';
import 'package:axiom/features/payments/services/url_opener.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ApiClient>(ApiClient(tokenStorage: TokenStorage()));
  });

  tearDown(Get.reset);

  test('registers the payment route dependencies', () {
    QuestPaymentBinding(questId: 'quest-1').dependencies();

    expect(Get.isRegistered<PaymentRepository>(), isTrue);
    expect(Get.isRegistered<UrlOpener>(), isTrue);
    expect(Get.isRegistered<QuestPaymentController>(), isTrue);
    expect(Get.find<PaymentRepository>(), isA<PaymentRepository>());
  });
}
