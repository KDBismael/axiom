import 'package:axiom/features/auth/controllers/auth_controller.dart';
import 'package:axiom/features/auth/models/user_model.dart';
import 'package:axiom/features/auth/repositories/auth_repository.dart';
import 'package:axiom/features/auth/services/apple_auth_service.dart';
import 'package:axiom/features/auth/services/google_auth_service.dart';
import 'package:axiom/core/api/token_storage.dart';
import 'package:axiom/features/payments/controllers/quest_payment_controller.dart';
import 'package:axiom/features/payments/models/stake_transaction.dart';
import 'package:axiom/features/payments/repositories/payment_repository.dart';
import 'package:axiom/features/payments/services/url_opener.dart';
import 'package:axiom/features/payments/views/quest_payment_view.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/quests/repositories/quest_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockGoogleAuthService extends Mock implements GoogleAuthService {}

class MockAppleAuthService extends Mock implements AppleAuthService {}

class MockQuestRepository extends Mock implements QuestRepository {}

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockUrlOpener extends Mock implements UrlOpener {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(Get.reset);

  testWidgets('shows actual fees and sends the edited Wave number', (
    tester,
  ) async {
    final auth = AuthController(
      authRepository: MockAuthRepository(),
      tokenStorage: MockTokenStorage(),
      googleAuthService: MockGoogleAuthService(),
      appleAuthService: MockAppleAuthService(),
    );
    auth.user.value = User(
      id: 'u-1',
      email: 'test@example.com',
      firstName: 'Awa',
      lastName: 'Koné',
      phone: '+2250700001234',
      role: 'user',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    Get.put<AuthController>(auth);

    final questRepository = MockQuestRepository();
    when(() => questRepository.fetchQuests()).thenAnswer(
      (_) async => [
        QuestModel(
          id: 'q-1',
          title: 'Méditer',
          description: '',
          creatorId: 'u-1',
          frequency: QuestFrequency.daily,
          durationDays: 21,
          targetPerPeriod: 1,
          startDate: DateTime(2026, 1, 1),
          deadline: DateTime(2026, 1, 22),
          gracePeriodDays: 0,
          riskLevel: QuestRiskLevel.medium,
          requiresProof: true,
          successThresholdPercent: 86,
          hasStake: true,
          stakeAmountXof: 10000,
          status: QuestStatus.pendingPayment,
          progress: 0,
          streakDays: 0,
        ),
      ],
    );
    when(
      () => questRepository.fetchMyAllyInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyOwnerInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyGroupInvitations(),
    ).thenAnswer((_) async => []);
    when(
      () => questRepository.fetchMyPauseRequests(),
    ).thenAnswer((_) async => []);
    final quests = Get.put(QuestListController(questRepository));
    await quests.loadQuests();

    final payments = MockPaymentRepository();
    const transaction = StakeTransaction(
      transactionId: 'tx-1',
      status: 'pending',
      paymentUrl: 'https://wave.example/pay',
    );
    when(
      () => payments.initiateStakePayment(
        'q-1',
        phoneNumber: any(named: 'phoneNumber'),
      ),
    ).thenAnswer((_) async => transaction);
    final opener = MockUrlOpener();
    when(() => opener.open(any())).thenAnswer((_) async => true);
    Get.put(QuestPaymentController(payments, quests, opener, 'q-1'));

    await tester.pumpWidget(const GetMaterialApp(home: QuestPaymentView()));
    await tester.pump();
    expect(find.text('10 000 XOF'), findsOneWidget);
    expect(find.text('500 XOF'), findsOneWidget);
    expect(find.text('CONFIRMER · 10 500 XOF'), findsOneWidget);
    expect(find.text('+225 07 ••• 12 34'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '+2250700998877');
    await tester.tap(find.text('Valider'));
    await tester.pump();
    expect(find.text('+225 07 ••• 88 77'), findsOneWidget);
    await tester.tap(find.text('CONFIRMER · 10 500 XOF'));
    await tester.pump();
    verify(
      () => payments.initiateStakePayment('q-1', phoneNumber: '+2250700998877'),
    ).called(1);
    verify(() => opener.open('https://wave.example/pay')).called(1);
    Get.find<QuestPaymentController>().stopPolling();
  });
}
