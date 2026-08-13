import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/quest_model.dart';
import 'quest_list_controller.dart';

class QuestCreateController extends GetxController {
  QuestCreateController(this._listController) {
    titleController.addListener(() => titleText.value = titleController.text);
    durationController.addListener(
      () => durationText.value = durationController.text,
    );
    targetPerPeriodController.addListener(
      () => targetPerPeriodText.value = targetPerPeriodController.text,
    );
    gracePeriodController.addListener(
      () => gracePeriodText.value = gracePeriodController.text,
    );
    stakeController.addListener(() => stakeText.value = stakeController.text);
  }

  final QuestListController _listController;

  /// Title/Description → Schedule & Rules → Allies (optional) → Stake
  /// (optional) → Review.
  static const stepCount = 5;
  static const paymentsEnabled = false;

  final currentStep = 0.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  final targetPerPeriodController = TextEditingController(text: '1');
  final gracePeriodController = TextEditingController(text: '0');
  final stakeController = TextEditingController();
  final allySearchController = TextEditingController();
  bool questSearchInitialized = false;

  final frequency = QuestFrequency.daily.obs;
  final startDate = Rx<DateTime>(DateTime.now());
  final deadline = Rx<DateTime>(DateTime.now().add(const Duration(days: 30)));
  final riskLevel = QuestRiskLevel.medium.obs;
  final requiresProof = false.obs;
  final successThresholdPercent = 80.obs;
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
  final durationText = '30'.obs;
  final targetPerPeriodText = '1'.obs;
  final gracePeriodText = '0'.obs;

  /// Same mirroring as [titleText], for the stake amount.
  final stakeText = ''.obs;

  bool get canProceedFromTitle => titleText.value.trim().isNotEmpty;

  bool get hasStakeAmount => double.tryParse(stakeText.value.trim()) != null;

  int get durationDays => math.max(1, int.tryParse(durationText.value) ?? 30);
  int get expectedPeriods =>
      expectedQuestPeriods(frequency.value, durationDays);
  int get requiredPeriods => requiredQuestPeriods(
    frequency: frequency.value,
    durationDays: durationDays,
    successThresholdPercent: successThresholdPercent.value,
  );
  int get missedPeriodsAllowed => toleratedMissedPeriods(
    frequency: frequency.value,
    durationDays: durationDays,
    successThresholdPercent: successThresholdPercent.value,
  );

  void setMissedPeriodsAllowed(int value) {
    successThresholdPercent.value = successThresholdForMissedPeriods(
      frequency: frequency.value,
      durationDays: durationDays,
      missedPeriods: value,
    );
  }

  int get targetPerPeriod =>
      math.max(1, int.tryParse(targetPerPeriodText.value) ?? 1);

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
        'gracePeriodDays': math.max(
          0,
          int.tryParse(gracePeriodController.text) ?? 0,
        ),
        'riskLevel': riskLevel.value.toJson(),
        'requiresProof': requiresProof.value,
        'successThresholdPercent': successThresholdPercent.value,
        'hasStake': paymentsEnabled && hasStake.value,
        if (paymentsEnabled && hasStake.value)
          'stakeAmountXof': double.tryParse(stakeController.text) ?? 0,
        if (paymentsEnabled && hasStake.value)
          'fundsDistribution': fundsDistribution.value.toJson(),
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
    stakeController.dispose();
    allySearchController.dispose();
    super.onClose();
  }
}
