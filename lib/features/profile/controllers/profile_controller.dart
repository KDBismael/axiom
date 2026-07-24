import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../models/country.dart';
import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../services/avatar_picker_service.dart';

class ProfileController extends GetxController {
  ProfileController(this._repository, this._avatarPickerService);

  final ProfileRepository _repository;
  final AvatarPickerService _avatarPickerService;

  static const _maxAvatarBytes = 5 * 1024 * 1024;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();

  /// The phone's dial-code country — [phoneController] holds only the
  /// local digits; the two are recomposed into one E.164-ish string on
  /// save.
  final country = Rx<Country>(xofZoneCountries.first);

  final language = 'fr'.obs;
  final notificationsEnabled = false.obs;
  final privacyLevel = ProfilePrivacyLevel.standard.obs;

  final profile = Rxn<Profile>();
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.getMe();
      _applyProfile(result);
    } on ProfileException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    final current = profile.value;
    if (current == null) return;

    final changes = <String, dynamic>{};
    if (firstNameController.text != current.firstName) {
      changes['firstName'] = firstNameController.text;
    }
    if (lastNameController.text != current.lastName) {
      changes['lastName'] = lastNameController.text;
    }
    final phone =
        phoneController.text.isEmpty ? null : '${country.value.dialCode}${phoneController.text}';
    if (phone != current.phone) changes['phone'] = phone;
    if (language.value != current.language) changes['language'] = language.value;
    if (notificationsEnabled.value != current.notificationsEnabled) {
      changes['notificationsEnabled'] = notificationsEnabled.value;
    }
    if (privacyLevel.value != current.privacyLevel) {
      changes['privacyLevel'] = privacyLevel.value.toJson();
    }

    if (changes.isEmpty) return;

    isSaving.value = true;
    errorMessage.value = null;
    try {
      final updated = await _repository.updateMe(changes);
      _applyProfile(updated);
    } on ProfileException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> pickAndUploadAvatar() async {
    // Guards against a second concurrent pick — e.g. a rapid double-tap —
    // which crashes image_picker's iOS channel if a picker session is
    // already in flight.
    if (isSaving.value) return;
    isSaving.value = true;
    errorMessage.value = null;
    try {
      final picked = await _avatarPickerService.pickImage();
      if (picked == null) return;

      if (picked.sizeBytes > _maxAvatarBytes) {
        errorMessage.value = 'Image trop volumineuse (5 Mo maximum).';
        return;
      }
      if (!picked.mimeType.startsWith('image/')) {
        errorMessage.value = 'Veuillez choisir une image.';
        return;
      }

      final fileId = await _repository.uploadAvatar(picked);
      final updated = await _repository.updateMe({'avatarUrl': '/files/$fileId'});
      _applyProfile(updated);
    } on ProfileException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSaving.value = false;
    }
  }

  void _applyProfile(Profile result) {
    profile.value = result;
    firstNameController.text = result.firstName;
    lastNameController.text = result.lastName;
    final phoneParts = splitPhoneNumber(result.phone);
    country.value = phoneParts.country;
    phoneController.text = phoneParts.localNumber;
    language.value = result.language;
    notificationsEnabled.value = result.notificationsEnabled;
    privacyLevel.value = result.privacyLevel;

    Get.find<AuthController>().user.value = User(
      id: result.id,
      email: result.email,
      firstName: result.firstName,
      lastName: result.lastName,
      phone: result.phone,
      avatarUrl: result.avatarUrl,
      role: result.role,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt,
    );
  }
}
