import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/services/apple_auth_service.dart';
import '../../features/auth/services/google_auth_service.dart';
import '../api/api_client.dart';
import '../api/token_storage.dart';
import '../services/deep_link_service.dart';
import '../services/pending_invite_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Called once explicitly in main() (so the session can be restored
    // before the first frame) and again by GetMaterialApp's own
    // initialBinding lifecycle — guard against double registration
    // clobbering the already-restored AuthController.
    if (Get.isRegistered<AuthController>()) return;

    Get.lazyPut<TokenStorage>(() => TokenStorage());
    Get.lazyPut<ApiClient>(() => ApiClient(tokenStorage: Get.find()));
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find()));
    Get.lazyPut<GoogleAuthService>(() => GoogleAuthService());
    Get.lazyPut<AppleAuthService>(() => AppleAuthService());
    Get.lazyPut<DeepLinkService>(() => DeepLinkService());

    // Permanent: auth state must survive across the whole app lifecycle,
    // not just one route — the first GetxService in this codebase.
    Get.put<AuthController>(
      AuthController(
        authRepository: Get.find(),
        tokenStorage: Get.find(),
        googleAuthService: Get.find(),
        appleAuthService: Get.find(),
      ),
      permanent: true,
    );
    Get.put<PendingInviteService>(PendingInviteService(), permanent: true);
  }
}
