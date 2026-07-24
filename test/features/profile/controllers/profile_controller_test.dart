import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:axiom/features/auth/controllers/auth_controller.dart';
import 'package:axiom/features/auth/repositories/auth_repository.dart';
import 'package:axiom/features/auth/services/apple_auth_service.dart';
import 'package:axiom/features/auth/services/google_auth_service.dart';
import 'package:axiom/features/profile/controllers/profile_controller.dart';
import 'package:axiom/features/profile/models/country.dart';
import 'package:axiom/features/profile/models/profile_model.dart';
import 'package:axiom/features/profile/repositories/profile_repository.dart';
import 'package:axiom/features/profile/services/avatar_picker_service.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAvatarPickerService extends Mock implements AvatarPickerService {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      PickedAvatar(
        bytes: Uint8List(0),
        sizeBytes: 0,
        filename: 'fallback.png',
        mimeType: 'image/png',
      ),
    );
  });

  late MockProfileRepository mockRepository;
  late MockAvatarPickerService mockAvatarPicker;
  late ProfileController controller;

  final baseProfile = Profile(
    id: 'u-1',
    email: 'jean@axiom.com',
    firstName: 'Jean',
    lastName: 'Dupont',
    phone: '+2250700000000',
    avatarUrl: null,
    language: 'fr',
    role: 'user',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    notificationsEnabled: true,
    privacyLevel: ProfilePrivacyLevel.standard,
  );

  setUp(() {
    mockRepository = MockProfileRepository();
    mockAvatarPicker = MockAvatarPickerService();
    controller = ProfileController(mockRepository, mockAvatarPicker);

    Get.put<AuthController>(
      AuthController(
        authRepository: MockAuthRepository(),
        tokenStorage: MockTokenStorage(),
        googleAuthService: MockGoogleAuthService(),
        appleAuthService: MockAppleAuthService(),
      ),
    );
  });

  tearDown(Get.reset);

  group('ProfileController.loadProfile', () {
    test('populates the text controllers and settings fields', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);

      await controller.loadProfile();

      expect(controller.firstNameController.text, 'Jean');
      expect(controller.lastNameController.text, 'Dupont');
      expect(controller.phoneController.text, '0700000000');
      expect(controller.country.value.dialCode, '+225');
      expect(controller.language.value, 'fr');
      expect(controller.notificationsEnabled.value, isTrue);
      expect(controller.privacyLevel.value, ProfilePrivacyLevel.standard);
      expect(controller.profile.value, baseProfile);
    });

    test('syncs AuthController.user after load', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);

      await controller.loadProfile();

      final user = Get.find<AuthController>().user.value;
      expect(user, isNotNull);
      expect(user!.firstName, 'Jean');
      expect(user.email, 'jean@axiom.com');
    });
  });

  group('ProfileController.save', () {
    test('sends only the fields that actually changed', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();

      controller.firstNameController.text = 'Marc';
      when(() => mockRepository.updateMe(any()))
          .thenAnswer((_) async => baseProfile);

      await controller.save();

      final captured = verify(() => mockRepository.updateMe(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(captured, {'firstName': 'Marc'});
    });

    test('makes no repository call when nothing changed', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();

      await controller.save();

      verifyNever(() => mockRepository.updateMe(any()));
    });

    test('composes the dial code with the local number when the phone changes', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();

      controller.phoneController.text = '0711111111';
      when(() => mockRepository.updateMe(any())).thenAnswer((_) async => baseProfile);

      await controller.save();

      final captured = verify(() => mockRepository.updateMe(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(captured, {'phone': '+2250711111111'});
    });

    test('recomposes the phone when only the country changes', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();

      controller.country.value = xofZoneCountries.firstWhere((c) => c.dialCode == '+221');
      when(() => mockRepository.updateMe(any())).thenAnswer((_) async => baseProfile);

      await controller.save();

      final captured = verify(() => mockRepository.updateMe(captureAny())).captured.single
          as Map<String, dynamic>;
      expect(captured, {'phone': '+2210700000000'});
    });

    test('makes no repository call when the same country+number round-trips', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();

      // No edits — country/local number are exactly what loadProfile derived.
      await controller.save();

      verifyNever(() => mockRepository.updateMe(any()));
    });

    test('failure surfaces the backend French message', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();
      controller.firstNameController.text = 'Marc';
      when(() => mockRepository.updateMe(any()))
          .thenThrow(ProfileException('Prénom invalide'));

      await controller.save();

      expect(controller.errorMessage.value, 'Prénom invalide');
    });

    test('syncs AuthController.user after a successful save', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();
      controller.firstNameController.text = 'Marc';
      final updated = Profile(
        id: baseProfile.id,
        email: baseProfile.email,
        firstName: 'Marc',
        lastName: baseProfile.lastName,
        phone: baseProfile.phone,
        avatarUrl: baseProfile.avatarUrl,
        language: baseProfile.language,
        role: baseProfile.role,
        createdAt: baseProfile.createdAt,
        updatedAt: baseProfile.updatedAt,
        notificationsEnabled: baseProfile.notificationsEnabled,
        privacyLevel: baseProfile.privacyLevel,
      );
      when(() => mockRepository.updateMe(any())).thenAnswer((_) async => updated);

      await controller.save();

      expect(Get.find<AuthController>().user.value!.firstName, 'Marc');
    });
  });

  group('ProfileController.pickAndUploadAvatar', () {
    final picked = PickedAvatar(
      bytes: Uint8List.fromList([1, 2, 3]),
      sizeBytes: 3,
      filename: 'avatar.png',
      mimeType: 'image/png',
    );

    test('uploads then patches avatarUrl, in order, and refreshes the profile', () async {
      when(() => mockRepository.getMe()).thenAnswer((_) async => baseProfile);
      await controller.loadProfile();

      when(() => mockAvatarPicker.pickImage()).thenAnswer((_) async => picked);
      when(() => mockRepository.uploadAvatar(picked)).thenAnswer((_) async => 'f-9');
      final withAvatar = Profile(
        id: baseProfile.id,
        email: baseProfile.email,
        firstName: baseProfile.firstName,
        lastName: baseProfile.lastName,
        phone: baseProfile.phone,
        avatarUrl: '/files/f-9',
        language: baseProfile.language,
        role: baseProfile.role,
        createdAt: baseProfile.createdAt,
        updatedAt: baseProfile.updatedAt,
        notificationsEnabled: baseProfile.notificationsEnabled,
        privacyLevel: baseProfile.privacyLevel,
      );
      when(() => mockRepository.updateMe({'avatarUrl': '/files/f-9'}))
          .thenAnswer((_) async => withAvatar);

      await controller.pickAndUploadAvatar();

      verifyInOrder([
        () => mockRepository.uploadAvatar(picked),
        () => mockRepository.updateMe({'avatarUrl': '/files/f-9'}),
      ]);
      expect(controller.profile.value!.avatarUrl, '/files/f-9');
    });

    test('rejects a file over 5MB without calling the repository', () async {
      final tooBig = PickedAvatar(
        bytes: Uint8List(0),
        sizeBytes: 6 * 1024 * 1024,
        filename: 'big.png',
        mimeType: 'image/png',
      );
      when(() => mockAvatarPicker.pickImage()).thenAnswer((_) async => tooBig);

      await controller.pickAndUploadAvatar();

      expect(controller.errorMessage.value, isNotNull);
      verifyNever(() => mockRepository.uploadAvatar(any()));
    });

    test('a second concurrent tap is ignored while a pick is already in flight', () async {
      final pickerCompleter = Completer<PickedAvatar?>();
      when(() => mockAvatarPicker.pickImage()).thenAnswer((_) => pickerCompleter.future);

      final first = controller.pickAndUploadAvatar();
      final second = controller.pickAndUploadAvatar();

      pickerCompleter.complete(null);
      await first;
      await second;

      verify(() => mockAvatarPicker.pickImage()).called(1);
    });
  });
}
