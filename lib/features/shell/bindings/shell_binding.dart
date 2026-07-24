import 'package:get/get.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/repositories/profile_repository.dart';
import '../../profile/services/avatar_picker_service.dart';
import '../../quests/controllers/quest_list_controller.dart';
import '../../quests/repositories/quest_repository.dart';
import '../../quests/services/evidence_picker_service.dart';
import '../../social/controllers/allies_controller.dart';
import '../../social/controllers/validations_controller.dart';
import '../../social/repositories/social_repository.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../payments/repositories/payment_repository.dart';
import '../../payments/services/url_opener.dart';
import '../controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController());
    Get.lazyPut<QuestRepository>(() => QuestRepository(Get.find()));
    Get.lazyPut<QuestListController>(() => QuestListController(Get.find()));
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(Get.find()));
    Get.lazyPut<UrlOpener>(() => UrlOpener());
    Get.lazyPut<EvidencePickerService>(() => EvidencePickerService());
    Get.lazyPut<SocialRepository>(() => SocialRepository(Get.find()));
    Get.lazyPut<AlliesController>(() => AlliesController(Get.find()));
    Get.lazyPut<ValidationsController>(() => ValidationsController(Get.find()));
    Get.lazyPut<ProfileRepository>(() => ProfileRepository(Get.find()));
    Get.lazyPut<AvatarPickerService>(() => AvatarPickerService());
    Get.lazyPut<ProfileController>(() => ProfileController(Get.find(), Get.find()));
    Get.lazyPut<NotificationRepository>(() => NotificationRepository(Get.find()));
    Get.lazyPut<NotificationController>(() => NotificationController(Get.find()));
  }
}
