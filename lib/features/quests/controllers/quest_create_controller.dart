import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/quest_ally.dart';
import '../models/quest_model.dart';
import 'quest_list_controller.dart';

/// A selectable candidate shown on the "Alliés" step — distinct from
/// [QuestAlly], which represents an ally already attached to a quest.
class QuestCandidateAlly {
  final String id;
  final String name;
  final String handle;

  const QuestCandidateAlly({
    required this.id,
    required this.name,
    required this.handle,
  });
}

enum FundsDistribution { allies, charity }

enum MobileMoneyProvider { orangeMoney, mtnMoney, moovMoney, wave }

class QuestCreateController extends GetxController {
  static const stepCount = 5;
  static const stakeStepIndex = 3;

  final currentStep = 0.obs;
  final titleController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  final stakeController = TextEditingController();
  final frequency = QuestFrequency.daily.obs;
  final selectedAllyIds = <String>{}.obs;
  final fundsDistribution = FundsDistribution.allies.obs;
  final paymentConfirmed = false.obs;
  final mobileMoneyProvider = MobileMoneyProvider.wave.obs;
  final phoneController = TextEditingController();

  /// Mirrors [titleController]'s text reactively — `TextEditingController`
  /// changes aren't observed by `Obx` on their own, so the footer's
  /// "SUIVANT" enabled-state reads this instead of the raw controller.
  final titleText = ''.obs;

  /// Same mirroring as [titleText], for the stake amount — used to decide
  /// whether the stake step's CTA reads "SUIVANT" or "CONTINUER VERS LE
  /// PAIEMENT" (only shown once a non-empty stake has been entered).
  final stakeText = ''.obs;

  static const mockCandidates = [
    QuestCandidateAlly(id: 'c1', name: 'Marcus Thorne', handle: '@mthorne'),
    QuestCandidateAlly(id: 'c2', name: 'Elena Vance', handle: '@evance_performance'),
  ];

  QuestCreateController() {
    titleController.addListener(() => titleText.value = titleController.text);
    stakeController.addListener(() => stakeText.value = stakeController.text);
  }

  bool get canProceedFromTitle => titleText.value.trim().isNotEmpty;

  bool get hasStakeAmount => double.tryParse(stakeText.value.trim()) != null;

  void nextStep() {
    if (currentStep.value == 0 && !canProceedFromTitle) return;
    if (currentStep.value < stepCount - 1) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  /// Confirms the mobile money payment and finalizes quest creation right
  /// there — the payment step is the terminal step of the staked-quest
  /// flow, it doesn't return to the review step.
  Future<void> submitFromPayment() async {
    paymentConfirmed.value = true;
    await submit();
  }

  void toggleAlly(String id) {
    if (selectedAllyIds.contains(id)) {
      selectedAllyIds.remove(id);
    } else {
      selectedAllyIds.add(id);
    }
  }

  Future<void> submit() async {
    final duration = int.tryParse(durationController.text) ?? 30;
    final stake = double.tryParse(stakeController.text);
    final allies = mockCandidates
        .where((c) => selectedAllyIds.contains(c.id))
        .map((c) => QuestAlly(name: c.name, approved: false))
        .toList();

    final quest = QuestModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      durationDays: duration,
      frequency: frequency.value,
      progress: 0,
      total: frequency.value == QuestFrequency.daily ? duration : (duration / 7).ceil(),
      hasStake: stake != null,
      stakeAmount: stake,
      allies: allies,
    );

    await Get.find<QuestListController>().createQuest(quest);
  }

  @override
  void onClose() {
    titleController.dispose();
    durationController.dispose();
    stakeController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
