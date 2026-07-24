import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/auth/controllers/auth_controller.dart';
import 'package:axiom/features/auth/repositories/auth_repository.dart';
import 'package:axiom/features/auth/services/apple_auth_service.dart';
import 'package:axiom/features/auth/services/google_auth_service.dart';
import 'package:axiom/features/profile/controllers/profile_controller.dart';
import 'package:axiom/features/profile/models/profile_model.dart';
import 'package:axiom/features/profile/repositories/profile_repository.dart';
import 'package:axiom/features/profile/services/avatar_picker_service.dart';
import 'package:axiom/features/profile/views/profile_view.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:axiom/features/social/controllers/allies_controller.dart';
import 'package:axiom/features/social/controllers/validations_controller.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAvatarPickerService extends Mock implements AvatarPickerService {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockQuestRepository extends Mock implements QuestRepository {}

class MockSocialRepository extends Mock implements SocialRepository {}

/// A layout smoke test, not a UI-behavior test: confirms the full scroll
/// extent of this content-heavy tab lays out without a RenderFlex/overflow
/// error, since the simulator sandbox in this environment has no working
/// input-injection path to scroll and verify visually below the fold.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(Get.reset);

  testWidgets('renders without layout overflow across its full scroll extent', (
    tester,
  ) async {
    final mockQuestRepository = MockQuestRepository();
    when(() => mockQuestRepository.fetchQuests()).thenAnswer((_) async => []);
    when(() => mockQuestRepository.fetchMyAllyInvitations()).thenAnswer((_) async => []);
    Get.put<QuestListController>(QuestListController(mockQuestRepository));

    final mockSocialRepository = MockSocialRepository();
    when(() => mockSocialRepository.fetchAllies()).thenAnswer((_) async => []);
    when(() => mockSocialRepository.fetchInvitations()).thenAnswer((_) async => []);
    when(() => mockSocialRepository.fetchAllyRequests()).thenAnswer((_) async => []);
    when(() => mockSocialRepository.fetchValidations(status: any(named: 'status')))
        .thenAnswer((_) async => []);
    Get.put<AlliesController>(AlliesController(mockSocialRepository));
    Get.put<ValidationsController>(ValidationsController(mockSocialRepository));

    Get.put<AuthController>(
      AuthController(
        authRepository: MockAuthRepository(),
        tokenStorage: MockTokenStorage(),
        googleAuthService: MockGoogleAuthService(),
        appleAuthService: MockAppleAuthService(),
      ),
    );

    final mockProfileRepository = MockProfileRepository();
    when(() => mockProfileRepository.getMe()).thenAnswer(
      (_) async => Profile(
        id: 'u-1',
        email: 'jean@axiom.com',
        firstName: 'Jean',
        lastName: 'Dupont',
        phone: null,
        avatarUrl: null,
        language: 'fr',
        role: 'user',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        notificationsEnabled: true,
        privacyLevel: ProfilePrivacyLevel.standard,
      ),
    );
    Get.put<ProfileController>(
      ProfileController(mockProfileRepository, MockAvatarPickerService()),
    );

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: ProfileView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pump();
    tester.takeException();

    expect(find.text('ENREGISTRER LES MODIFICATIONS'), findsOneWidget);
    expect(find.text('STATISTIQUES'), findsOneWidget);
  });
}
