import 'package:get/get.dart';
import '../services/evidence_picker_service.dart';

class EvidencePickerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EvidencePickerService>(() => EvidencePickerService(), fenix: true);
  }
}
