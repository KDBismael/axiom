import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/quest_model.dart';
import 'quest_list_controller.dart';

class QuestCreateController extends GetxController {
  QuestCreateController(this._listController) {
    titleController.addListener(() => titleText.value = titleController.text);
    stakeController.addListener(() => stakeText.value = stakeController.text);
  }

  final QuestListController _listController;

  /// Title/Description → Schedule & Rules → Allies (optional) → Stake
  /// (optional) → Review.
  static const stepCount = 5;

  final currentStep = 0.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  final targetPerPeriodController = TextEditingController(text: '1');
  final gracePeriodController = TextEditingController(text: '0');
  final successThresholdController = TextEditingController(text: '80');
  final stakeController = TextEditingController();

  final frequency = QuestFrequency.daily.obs;
  final startDate = Rx<DateTime>(DateTime.now());
  final deadline = Rx<DateTime>(DateTime.now().add(const Duration(days: 30)));
  final riskLevel = QuestRiskLevel.medium.obs;
  final requiresProof = false.obs;
  final hasStake = false.obs;
  final fundsDistribution = FundsDistribution.allies.obs;

  /// Friends selected to be invited as this quest's accountability allies —
  /// a real invitation each must accept, not an automatic attachment.
  final selectedAllyIds = <String>{}.obs;

  void toggleAlly(String userId) {
    if (!selectedAllyIds.remove(userId)) selectedAllyIds.add(userId);
  }

  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  /// Mirrors [titleController]'s text reactively — `TextEditingController`
  /// changes aren't observed by `Obx` on their own, so the footer's
  /// "SUIVANT" enabled-state reads this instead of the raw controller.
  final titleText = ''.obs;

  /// Same mirroring as [titleText], for the stake amount.
  final stakeText = ''.obs;

  bool get canProceedFromTitle => titleText.value.trim().isNotEmpty;

  bool get hasStakeAmount => double.tryParse(stakeText.value.trim()) != null;

  void nextStep() {
    if (currentStep.value == 0 && !canProceedFromTitle) return;
    if (currentStep.value < stepCount - 1) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  /// Submits the quest to the backend. Returns true on success; on
  /// failure, [errorMessage] carries the backend's French message.
  Future<bool> submit() async {
    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      final payload = <String, dynamic>{
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'frequency': frequency.value.toJson(),
        'durationDays': int.tryParse(durationController.text) ?? 30,
        'targetPerPeriod': int.tryParse(targetPerPeriodController.text) ?? 1,
        'startDate': startDate.value.toIso8601String(),
        'deadline': deadline.value.toIso8601String(),
        'gracePeriodDays': int.tryParse(gracePeriodController.text) ?? 0,
        'riskLevel': riskLevel.value.toJson(),
        'requiresProof': requiresProof.value,
        'successThresholdPercent': int.tryParse(successThresholdController.text) ?? 80,
        'hasStake': hasStake.value,
        if (hasStake.value)
          'stakeAmountXof': double.tryParse(stakeController.text) ?? 0,
        if (hasStake.value) 'fundsDistribution': fundsDistribution.value.toJson(),
        if (selectedAllyIds.isNotEmpty) 'allyUserIds': selectedAllyIds.toList(),
      };

      await _listController.createQuest(payload);
      if (_listController.errorMessage.value != null) {
        errorMessage.value = _listController.errorMessage.value;
        return false;
      }
      return true;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
    targetPerPeriodController.dispose();
    gracePeriodController.dispose();
    successThresholdController.dispose();
    stakeController.dispose();
    super.onClose();
  }
}
