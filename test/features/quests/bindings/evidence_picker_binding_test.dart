import 'package:axiom/features/quests/bindings/evidence_picker_binding.dart';
import 'package:axiom/features/quests/services/evidence_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);
  test('recreates the picker after the first proof route is disposed', () async {
    Get.testMode = true;
    EvidencePickerBinding().dependencies();
    final first = Get.find<EvidencePickerService>();
    await Get.delete<EvidencePickerService>();
    expect(Get.find<EvidencePickerService>(), isNot(same(first)));
  });
}
