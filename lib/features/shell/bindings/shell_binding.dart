import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../onboarding/controllers/guided_tour_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../profile/services/avatar_picker_service.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/repositories/quest_repository.dart';
import '../../quests/bindings/evidence_picker_binding.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/controllers/validations_controller.dart';
import '../../social/repositories/social_repository.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../payments/services/url_opener.dart';
import '../../rank/controllers/rank_controller.dart';
import '../../rank/repositories/rank_repository.dart';
import '../controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    Get.lazyPut<QuestRepository>(() => QuestRepository(Get.find()));
    Get.lazyPut<QuestListController>(() => QuestListController(Get.find()));
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(Get.find()));
    Get.lazyPut<UrlOpener>(() => UrlOpener());
    EvidencePickerBinding().dependencies();
    if (!Get.isRegistered<SocialRepository>()) {
      Get.lazyPut<SocialRepository>(
        () => SocialRepository(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AlliesController>()) {
      Get.lazyPut<AlliesController>(
        () => AlliesController(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ValidationsController>()) {
      Get.lazyPut<ValidationsController>(
        () => ValidationsController(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<AvatarPickerService>()) {
      Get.lazyPut<AvatarPickerService>(
        () => AvatarPickerService(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put<ProfileController>(
        ProfileController(Get.find(), Get.find()),
        permanent: true,
      );
    }
    Get.lazyPut<NotificationRepository>(
      () => NotificationRepository(Get.find()),
    );
    Get.lazyPut<NotificationController>(
      () => NotificationController(Get.find()),
    );
    {
      // Permanent: a lazyPut is deleted with whichever route first looked
      // it up (e.g. the notification dialog), which crashed the tour.
      // Replaced on every shell entry (each login) so it never holds the
      // previous session's QuestListController.
      if (Get.isRegistered<GuidedTourController>()) {
        Get.delete<GuidedTourController>(force: true);
      }
      Get.put<GuidedTourController>(
        GuidedTourController(currentUser: Get.find<AuthController>().user),
        permanent: true,
      );
    }
    if (!Get.isRegistered<RankRepository>()) {
      Get.lazyPut<RankRepository>(
        () => RankRepository(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<RankController>()) {
      Get.put<RankController>(RankController(Get.find()), permanent: true);
    }
  }
}
