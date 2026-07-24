import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/social/controllers/validations_controller.dart';
import 'package:axiom/features/social/models/ally_validation_request.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';
import 'package:axiom/features/social/views/ally_validations_view.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    final mockTokenStorage = MockTokenStorage();
    when(() => mockTokenStorage.readAccessToken()).thenAnswer((_) async => 'access-token');
    Get.put<TokenStorage>(mockTokenStorage);
  });

  tearDown(Get.reset);

  const request1 = AllyValidationRequest(
    id: 'val1',
    questId: 'q-1',
    questTitle: '50 Pages par jour',
    evidenceId: 'ev-1',
    proofType: ProofType.photo,
    fileId: 'f-1',
    status: ValidationDecisionStatus.pending,
  );
  const request2 = AllyValidationRequest(
    id: 'val2',
    questId: 'q-2',
    questTitle: 'Méditation Matinale',
    evidenceId: 'ev-2',
    proofType: ProofType.text,
    textContent:
        'Session de 20 minutes complétée à 06h15. Focus sur la respiration profonde.',
    status: ValidationDecisionStatus.pending,
  );

  testWidgets('renders both photo-proof and text-proof cards with their evidence', (
    tester,
  ) async {
    final mockRepository = MockSocialRepository();
    when(() => mockRepository.fetchValidations(status: any(named: 'status')))
        .thenAnswer((_) async => [request1, request2]);
    Get.put<ValidationsController>(ValidationsController(mockRepository));

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: AllyValidationsView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    expect(find.text('Quête : 50 Pages par jour'), findsOneWidget);
    expect(find.text('PREUVE PHOTO'), findsOneWidget);

    expect(find.text('Quête : Méditation Matinale'), findsOneWidget);
    expect(find.textContaining('Session de 20 minutes complétée'), findsOneWidget);
  });

  testWidgets('APPROUVER removes the card and updates controller state', (tester) async {
    final mockRepository = MockSocialRepository();
    var approved = false;
    when(() => mockRepository.fetchValidations(status: any(named: 'status'))).thenAnswer(
      (_) async => approved ? [request2] : [request1, request2],
    );
    when(() => mockRepository.decideValidation('val1', approved: true)).thenAnswer((_) async {
      approved = true;
    });
    final controller = Get.put<ValidationsController>(ValidationsController(mockRepository));

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: AllyValidationsView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    expect(controller.pendingValidations.length, 2);

    await tester.tap(find.text('APPROUVER').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.pendingValidations.length, 1);
    expect(find.text('Quête : 50 Pages par jour'), findsNothing);
  });

  testWidgets('an empty validations list shows the empty state', (tester) async {
    final mockRepository = MockSocialRepository();
    when(() => mockRepository.fetchValidations(status: any(named: 'status')))
        .thenAnswer((_) async => const []);
    Get.put<ValidationsController>(ValidationsController(mockRepository));

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const Scaffold(body: AllyValidationsView())),
    );
    await tester.pump(const Duration(milliseconds: 350));
    tester.takeException();

    expect(find.text('FIN DES VALIDATIONS URGENTES'), findsOneWidget);
  });
}
