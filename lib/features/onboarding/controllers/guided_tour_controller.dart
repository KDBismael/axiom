import 'dart:async';

import 'package:get/get.dart';
import '../../../core/utils/idempotency_key.dart';
import '../../auth/models/user_model.dart';
import '../../notifications/services/push_notification_service.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/models/quest_model.dart';
import '../../quests/repositories/quest_repository.dart';
import '../../social/repositories/social_repository.dart';
import '../models/first_quest_template.dart';

enum GuidedTourStep {
  /// Not decided yet, or not applicable (tour already completed).
  idle,

  /// Bubble on "+ NOUVELLE QUÊTE" → template sheet.
  createQuest,

  /// "Quête lancée" screen, with the invite-an-ally step.
  launched,

  /// Bubble on the new quest card: "Valide chaque jour ici".
  checkIn,
  done,
}

/// First-run guided tour after signup: create a first quest, invite an
/// ally, learn where to check in. Shown once per account — completion is
/// stored on the backend (`User.onboardingCompletedAt`), so it never
/// replays after a reinstall or on another device. The home view renders
/// the bubbles; this controller only owns the state machine.
class GuidedTourController extends GetxController {
  /// Dependencies are resolved on first use, not here: this controller is
  /// registered in ShellBinding, and looking up QuestListController that
  /// early ties it to the wrong route, so GetX deletes it when a later
  /// screen closes. Tests inject them directly.
  GuidedTourController({
    QuestListController? quests,
    ProfileRepository? profileRepository,
    SocialRepository? socialRepository,
    required Rxn<User> currentUser,
  }) : _questsOverride = quests,
       _profileOverride = profileRepository,
       _socialOverride = socialRepository,
       _currentUser = currentUser;

  final QuestListController? _questsOverride;
  final ProfileRepository? _profileOverride;
  final SocialRepository? _socialOverride;
  final Rxn<User> _currentUser;

  QuestListController get _quests =>
      _questsOverride ?? Get.find<QuestListController>();
  ProfileRepository get _profileRepository =>
      _profileOverride ?? Get.find<ProfileRepository>();
  SocialRepository get _socialRepository =>
      _socialOverride ?? Get.find<SocialRepository>();

  final step = GuidedTourStep.idle.obs;
  final launchedQuest = Rxn<QuestModel>();
  final isLaunching = false.obs;
  final inviteShared = false.obs;
  final errorMessage = RxnString();

  /// One key for the whole tour: a retried template launch never creates
  /// a second quest.
  final String _creationKey = newIdempotencyKey();
  bool _completed = false;
  Worker? _questsWorker;
  Worker? _userWorker;
  String? _userId;

  @override
  void onInit() {
    super.onInit();
    // Registered permanently (it must outlive dialogs and routes), so a
    // logout → login as someone else has to start a fresh tour.
    _userId = _currentUser.value?.id;
    _userWorker = ever<User?>(_currentUser, (user) {
      if (user?.id == _userId) return;
      _userId = user?.id;
      _reset();
    });
  }

  void _watchQuests() {
    // A user who picks "Créer ma propre quête" goes through the full
    // wizard (which has its own allies step): once that quest shows up,
    // jump straight to the check-in bubble.
    _questsWorker ??= ever<List<QuestModel>>(_quests.quests, (list) {
      if (step.value == GuidedTourStep.createQuest &&
          !isLaunching.value &&
          list.isNotEmpty) {
        step.value = GuidedTourStep.checkIn;
      }
    });
  }

  void _reset() {
    _completed = false;
    step.value = GuidedTourStep.idle;
    launchedQuest.value = null;
    inviteShared.value = false;
    errorMessage.value = null;
  }

  /// Decides whether the tour applies; call once the quest list loaded.
  Future<void> evaluate() async {
    if (step.value != GuidedTourStep.idle || _completed) return;
    final user = _currentUser.value;
    if (user == null || user.onboardingCompletedAt != null) return;
    if (_quests.quests.isNotEmpty) {
      // Existing user from before the tour shipped: nothing to teach.
      await finish();
      return;
    }
    _watchQuests();
    step.value = GuidedTourStep.createQuest;
  }

  Future<QuestModel?> launchTemplate(FirstQuestTemplate template) async {
    if (isLaunching.value) return null;
    isLaunching.value = true;
    errorMessage.value = null;
    try {
      final created = await _quests.createQuest(
        template.toPayload(DateTime.now()),
        idempotencyKey: _creationKey,
      );
      if (created == null) {
        errorMessage.value = _quests.errorMessage.value;
        return null;
      }
      launchedQuest.value = created;
      step.value = GuidedTourStep.launched;
      return created;
    } on QuestException catch (e) {
      errorMessage.value = e.message;
      return null;
    } finally {
      isLaunching.value = false;
    }
  }

  /// Creates a fresh ally invite link and wraps it in a ready-to-send
  /// message. Null on failure, with [errorMessage] set.
  Future<String?> prepareInviteMessage() async {
    errorMessage.value = null;
    try {
      final invitation = await _socialRepository.createInvitation();
      final link = invitation.deepLink;
      if (link == null) {
        errorMessage.value = "Le lien d'invitation n'a pas pu être créé.";
        return null;
      }
      final title = launchedQuest.value?.title;
      final goal = title == null ? 'mon objectif' : '« $title »';
      return "Je me lance un défi : $goal. Deviens mon allié sur Ndeli "
          "pour m'encourager et valider mes progrès 💪\n$link";
    } on SocialException catch (e) {
      errorMessage.value = e.message;
      return null;
    }
  }

  void markInviteShared() => inviteShared.value = true;

  /// Leaves the launch screen for the home check-in bubble.
  void continueToCheckIn() {
    if (step.value == GuidedTourStep.launched) {
      step.value = GuidedTourStep.checkIn;
    }
  }

  /// Ends (or skips) the tour for good. Local state flips immediately; a
  /// failed backend write is retried by [evaluate] on the next launch.
  Future<void> finish() async {
    if (_completed) return;
    _completed = true;
    step.value = GuidedTourStep.done;
    final user = _currentUser.value;
    if (user != null) {
      _currentUser.value = user.copyWith(onboardingCompletedAt: DateTime.now());
    }
    try {
      await _profileRepository.updateMe({'onboardingCompleted': true});
    } catch (_) {
      // Offline or server error: the tour still ends for this session.
    }
    // The notification question waits for the tour to be out of the way.
    if (Get.isRegistered<PushNotificationService>()) {
      unawaited(Get.find<PushNotificationService>().registerCurrentDevice());
    }
  }

  @override
  void onClose() {
    _questsWorker?.dispose();
    _userWorker?.dispose();
    super.onClose();
  }
}
