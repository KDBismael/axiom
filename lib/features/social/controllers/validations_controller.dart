import 'package:get/get.dart';
import '../models/ally_validation_request.dart';
import '../repositories/social_repository.dart';

class ValidationsController extends GetxController {
  ValidationsController(this._repository);

  final SocialRepository _repository;

  final validations = <AllyValidationRequest>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  List<AllyValidationRequest> get pendingValidations =>
      validations.where((v) => v.status == ValidationDecisionStatus.pending).toList();

  List<AllyValidationRequest> get decidedValidations => validations
      .where(
        (v) =>
            v.status == ValidationDecisionStatus.approved ||
            v.status == ValidationDecisionStatus.rejected,
      )
      .toList();

  @override
  void onInit() {
    super.onInit();
    loadValidations();
  }

  Future<void> loadValidations() async {
    isLoading.value = true;
    try {
      validations.assignAll(await _repository.fetchValidations());
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> decide(String id, {required bool approved}) async {
    errorMessage.value = null;
    try {
      await _repository.decideValidation(id, approved: approved);
      await loadValidations();
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }
}
