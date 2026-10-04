import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/quest_model.dart';
import 'quest_list_controller.dart';
import '../../payments/services/payment_feature_config.dart';

class QuestCreateController extends GetxController {
  QuestCreateController(
    this._listController, {
    PaymentFeatureConfig paymentConfig = PaymentFeatureConfig.current,
  }) : _paymentConfig = paymentConfig {
    titleController.addListener(() => titleText.value = titleController.text);
    descriptionController.addListener(
      () => descriptionText.value = descriptionController.text,
    );
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
  final PaymentFeatureConfig _paymentConfig;

  /// Type → rules → allies/members → [stake] → review.
  int get stepCount => stepTitles.length;
  List<String> get stepTitles => [
    'Type de quête',
    'Règles',
    isCollective.value ? 'Membres' : 'Alliés',
    if (!isCollective.value) 'Enjeu',
    'Récapitulatif',
  ];

  bool get canProceed => switch (currentStep.value) {
    1 =>
      canProceedFromDetails &&
          (!createForSomeoneElse.value || canProceedFromInvitee),
    _ => true,
  };
  bool get paymentsEnabled => _paymentConfig.isEnabled;

  final currentStep = 0.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController(text: '30');
  final targetPerPeriodController = TextEditingController(text: '1');
  final gracePeriodController = TextEditingController(text: '0');
  final stakeController = TextEditingController();
  final allySearchController = TextEditingController();
  final inviteeSearchController = TextEditingController();

  /// Whether this quest is being created on behalf of someone else — the
  /// invitee becomes the quest owner once they accept, and the creator
  /// (this user) becomes an accountability partner automatically.
  final createForSomeoneElse = false.obs;
  final selectedInviteeId = RxnString();
  final selectedInviteeName = RxnString();

  void selectInvitee(String userId, {String? name}) {
    if (selectedInviteeId.value == userId) {
      selectedInviteeId.value = null;
      selectedInviteeName.value = null;
    } else {
      setInvitee(userId, name: name);
    }
  }

  void setInvitee(String userId, {String? name}) {
    selectedInviteeId.value = userId;
    selectedInviteeName.value = name ?? userId;
  }

  /// A collective quest: everyone selected in [selectedAllyIds] joins as a
  /// full co-participant (their own Quest, identical rules) and validator
  /// for every other member, not a proof-only ally. Mutually exclusive with
  /// [createForSomeoneElse] — a quest can't be both sponsored to one person
  /// and shared by a group.
  final isCollective = false.obs;

  final frequency = QuestFrequency.daily.obs;
  final startDate = Rx<DateTime>(DateTime.now());
  final deadline = Rx<DateTime>(DateTime.now().add(const Duration(days: 30)));
  final requiresProof = false.obs;
  final successThresholdPercent = 80.obs;
  final hasStake = false.obs;
  final fundsDistribution = FundsDistribution.allies.obs;

  /// Below this many XOF (or no stake at all): [QuestRiskLevel.low]. From
  /// here up to [_highRiskThresholdXof]: [QuestRiskLevel.medium]. At or
  /// above [_highRiskThresholdXof]: [QuestRiskLevel.high].
  static const _mediumRiskThresholdXof = 5000;
  static const _highRiskThresholdXof = 20000;

  static QuestRiskLevel riskLevelForStake(double? amountXof) {
    if (amountXof == null || amountXof < _mediumRiskThresholdXof) {
      return QuestRiskLevel.low;
    }
    if (amountXof < _highRiskThresholdXof) return QuestRiskLevel.medium;
    return QuestRiskLevel.high;
  }

  /// Set automatically from the live stake amount — no stake, or a stake
  /// below the low threshold, is the lowest risk; the user never picks this
  /// directly. A plain getter (not an `Rx`) so it's always in sync with
  /// [hasStake]/[stakeText] with no separate state to keep updated —
  /// reading it from inside an `Obx` reacts to those the same way reading
  /// them directly would.
  double get effectiveStakeAmount =>
      hasStake.value && !isCollective.value && paymentsEnabled
      ? double.tryParse(stakeText.value.trim()) ?? 0
      : 0;

  QuestRiskLevel get riskLevel => riskLevelForStake(effectiveStakeAmount);

  void selectStake(int amount) {
    if (amount > 0 && (!paymentsEnabled || isCollective.value)) return;
    hasStake.value = amount > 0;
    stakeController.text = amount > 0 ? '$amount' : '';
  }

  void adjustDuration(int delta) {
    durationController.text = '${math.max(1, durationDays + delta)}';
    deadline.value = startDate.value.add(Duration(days: durationDays));
  }

  void adjustTarget(int delta) {
    targetPerPeriodController.text = '${math.max(1, targetPerPeriod + delta)}';
  }

  /// Friends selected to be invited as this quest's accountability allies —
  /// a real invitation each must accept, not an automatic attachment.
  final selectedAllyIds = <String>{}.obs;
  final selectedAllyNames = <String, String>{}.obs;

  void toggleAlly(String userId, {String? name}) {
    if (selectedAllyIds.remove(userId)) {
      selectedAllyNames.remove(userId);
    } else {
      selectedAllyIds.add(userId);
      selectedAllyNames[userId] = name ?? userId;
    }
  }

  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  /// The quest just created by [submit]; the view reads this to decide
  /// whether to navigate to the payment screen (staked quest, still
  /// `pending_payment`) or simply pop back (no stake).
  final createdQuest = Rxn<QuestModel>();

  /// Mirrors [titleController]'s text reactively — `TextEditingController`
  /// changes aren't observed by `Obx` on their own, so the footer's
  /// "SUIVANT" enabled-state reads this instead of the raw controller.
  final titleText = ''.obs;
  final descriptionText = ''.obs;
  final durationText = '30'.obs;
  final targetPerPeriodText = '1'.obs;
  final gracePeriodText = '0'.obs;

  /// Same mirroring as [titleText], for the stake amount.
  final stakeText = ''.obs;

  bool get canProceedFromTitle => titleText.value.trim().isNotEmpty;
  bool get canProceedFromDetails =>
      canProceedFromTitle && descriptionText.value.trim().isNotEmpty;

  bool get canProceedFromInvitee => selectedInviteeId.value != null;

  /// Index of the invitee-selection step, only present when sponsoring.
  static const inviteeStepIndex = 1;

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
    if (!canProceed || isSubmitting.value) return;
    if (currentStep.value < stepCount - 1) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  /// Submits the quest to the backend. Returns true on success; on
  /// failure, [errorMessage] carries the backend's French message.
  Future<bool> submit() async {
    if (!canProceedFromTitle) {
      errorMessage.value = 'Le titre est obligatoire.';
      return false;
    }
    if (descriptionText.value.trim().isEmpty) {
      errorMessage.value = 'La description est obligatoire.';
      return false;
    }
    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      if (isCollective.value) {
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
          'riskLevel': riskLevel.toJson(),
          'requiresProof': requiresProof.value,
          'successThresholdPercent': successThresholdPercent.value,
          if (selectedAllyIds.isNotEmpty)
            'memberUserIds': selectedAllyIds.toList(),
        };
        final created = await _listController.createQuestGroup(payload);
        if (created == null) {
          errorMessage.value = _listController.errorMessage.value;
          return false;
        }
        createdQuest.value = created;
        return true;
      }

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
        'riskLevel': riskLevel.toJson(),
        'requiresProof': requiresProof.value,
        'successThresholdPercent': successThresholdPercent.value,
        'hasStake': paymentsEnabled && hasStake.value,
        if (paymentsEnabled && hasStake.value)
          'stakeAmountXof': double.tryParse(stakeController.text) ?? 0,
        if (paymentsEnabled && hasStake.value)
          'fundsDistribution': fundsDistribution.value.toJson(),
        if (selectedAllyIds.isNotEmpty) 'allyUserIds': selectedAllyIds.toList(),
        if (createForSomeoneElse.value && selectedInviteeId.value != null)
          'inviteeId': selectedInviteeId.value,
      };

      final created = await _listController.createQuest(payload);
      if (created == null) {
        errorMessage.value = _listController.errorMessage.value;
        return false;
      }
      createdQuest.value = created;
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
    inviteeSearchController.dispose();
    super.onClose();
  }
}
