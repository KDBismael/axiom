import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/payments/controllers/quest_payment_controller.dart';
import 'package:axiom/features/payments/models/stake_transaction.dart';
import 'package:axiom/features/payments/repositories/payment_repository.dart';
import 'package:axiom/features/payments/services/url_opener.dart';
import 'package:axiom/features/quests/controllers/quest_list_controller.dart';
import 'package:axiom/features/quests/models/quest_model.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockQuestListController extends Mock implements QuestListController {}

class MockUrlOpener extends Mock implements UrlOpener {}

QuestModel _quest({required QuestStatus status}) => QuestModel(
  id: 'q-1',
  title: 'Test',
  description: 'desc',
  creatorId: 'user-1',
  frequency: QuestFrequency.daily,
  durationDays: 10,
  targetPerPeriod: 1,
  startDate: DateTime(2026, 1, 1),
  deadline: DateTime(2026, 1, 11),
  gracePeriodDays: 0,
  riskLevel: QuestRiskLevel.medium,
  requiresProof: false,
  successThresholdPercent: 80,
  hasStake: true,
  stakeAmountXof: 5000,
  fundsDistribution: FundsDistribution.allies,
  status: status,
  progress: 0,
  streakDays: 0,
);

void main() {
  late MockPaymentRepository mockRepository;
  late MockQuestListController mockQuestList;
  late MockUrlOpener mockUrlOpener;
  late QuestPaymentController controller;

  const transaction = StakeTransaction(
    transactionId: 'tx-1',
    geniusReference: 'MTX-ABC',
    paymentUrl: 'https://wave.com/pay/abc',
    status: 'pending',
    amountXof: 5000,
    feesXof: 150,
  );

  setUp(() {
    mockRepository = MockPaymentRepository();
    mockQuestList = MockQuestListController();
    mockUrlOpener = MockUrlOpener();
    when(() => mockUrlOpener.open(any())).thenAnswer((_) async => true);
    controller = QuestPaymentController(
      mockRepository,
      mockQuestList,
      mockUrlOpener,
      'q-1',
      pollInterval: const Duration(milliseconds: 10),
    );
  });

  tearDown(() {
    controller.onClose();
  });

  group('QuestPaymentController.onInit', () {
    test('does not auto-trigger payment - waits for the user to confirm the fees/total first', () async {
      controller.onInit();
      await Future.delayed(Duration.zero);

      verifyNever(
        () => mockRepository.initiateStakePayment(
          any(),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      );
      expect(controller.transaction.value, isNull);
    });
  });

  group('QuestPaymentController.pay', () {
    test('stores the transaction and opens the payment URL', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => transaction);
      when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
      when(
        () => mockQuestList.findById('q-1'),
      ).thenReturn(_quest(status: QuestStatus.pendingPayment));

      await controller.pay(phoneNumber: '+2250700000000');

      expect(controller.transaction.value, transaction);
      verify(() => mockUrlOpener.open('https://wave.com/pay/abc')).called(1);
      controller.stopPolling();
    });

    test('surfaces the backend error and does not open a URL', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenThrow(
        PaymentException('Numéro de téléphone requis pour le paiement Wave'),
      );

      await controller.pay();

      expect(
        controller.errorMessage.value,
        'Numéro de téléphone requis pour le paiement Wave',
      );
      verifyNever(() => mockUrlOpener.open(any()));
    });
  });

  group('QuestPaymentController polling', () {
    test('stops and reports success once the quest becomes active', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => transaction);
      when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
      var callCount = 0;
      when(() => mockQuestList.findById('q-1')).thenAnswer((_) {
        callCount++;
        return _quest(
          status: callCount < 3
              ? QuestStatus.pendingPayment
              : QuestStatus.active,
        );
      });

      await controller.pay();
      await Future.delayed(const Duration(milliseconds: 80));

      expect(controller.isPolling.value, isFalse);
      expect(controller.paymentSucceeded.value, isTrue);
    });

    test(
      'reports timeout when the quest stays pending after max attempts',
      () async {
        when(
          () => mockRepository.initiateStakePayment(
            'q-1',
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).thenAnswer((_) async => transaction);
        when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
        when(
          () => mockQuestList.findById('q-1'),
        ).thenReturn(_quest(status: QuestStatus.pendingPayment));

        final shortController = QuestPaymentController(
          mockRepository,
          mockQuestList,
          mockUrlOpener,
          'q-1',
          pollInterval: const Duration(milliseconds: 5),
          maxPollAttempts: 3,
        );

        await shortController.pay();
        await Future.delayed(const Duration(milliseconds: 60));

        expect(shortController.isPolling.value, isFalse);
        expect(shortController.paymentSucceeded.value, isFalse);
        expect(shortController.paymentTimedOut.value, isTrue);
        shortController.onClose();
      },
    );

    test('a manual check stops polling early on success', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => transaction);
      when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
      when(
        () => mockQuestList.findById('q-1'),
      ).thenReturn(_quest(status: QuestStatus.active));

      await controller.pay();
      await controller.checkNow();

      expect(controller.isPolling.value, isFalse);
      expect(controller.paymentSucceeded.value, isTrue);
    });
  });

  group('QuestPaymentController retry', () {
    test(
      'calling pay again after a timeout re-attempts against the same quest',
      () async {
        when(
          () => mockRepository.initiateStakePayment(
            'q-1',
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).thenAnswer((_) async => transaction);
        when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
        when(
          () => mockQuestList.findById('q-1'),
        ).thenReturn(_quest(status: QuestStatus.pendingPayment));

        await controller.pay();
        controller.stopPolling();
        await controller.pay();

        verify(
          () => mockRepository.initiateStakePayment(
            'q-1',
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).called(2);
        expect(controller.transaction.value, transaction);
      },
    );
  });

  group('QuestPaymentController topUp mode', () {
    late QuestPaymentController topUpController;

    setUp(() {
      topUpController = QuestPaymentController(
        mockRepository,
        mockQuestList,
        mockUrlOpener,
        'q-1',
        topUp: const StakeTopUp(
          amountXof: 1500,
          fundsDistribution: FundsDistribution.charity,
        ),
        pollInterval: const Duration(milliseconds: 10),
      );
      when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
    });

    tearDown(() {
      topUpController.onClose();
    });

    test('forwards the top-up amount and funds distribution to the repository', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
          additionalAmountXof: 1500,
          fundsDistribution: FundsDistribution.charity,
        ),
      ).thenAnswer((_) async => transaction);

      await topUpController.pay();

      verify(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: null,
          additionalAmountXof: 1500,
          fundsDistribution: FundsDistribution.charity,
        ),
      ).called(1);
    });

    test('detects success by polling the transaction, not the quest status', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
          additionalAmountXof: any(named: 'additionalAmountXof'),
          fundsDistribution: any(named: 'fundsDistribution'),
        ),
      ).thenAnswer((_) async => transaction);
      // The quest never leaves 'active' — that's the whole point of a
      // top-up, so success must come from the transaction's own status.
      when(
        () => mockQuestList.findById('q-1'),
      ).thenReturn(_quest(status: QuestStatus.active));
      var pollCount = 0;
      when(() => mockRepository.getTransaction('tx-1')).thenAnswer((_) async {
        pollCount++;
        return StakeTransaction(
          transactionId: 'tx-1',
          status: pollCount < 2 ? 'pending' : 'completed',
        );
      });

      await topUpController.pay();
      await Future.delayed(const Duration(milliseconds: 80));

      expect(topUpController.isPolling.value, isFalse);
      expect(topUpController.paymentSucceeded.value, isTrue);
    });

    test('times out if the transaction never completes', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
          additionalAmountXof: any(named: 'additionalAmountXof'),
          fundsDistribution: any(named: 'fundsDistribution'),
        ),
      ).thenAnswer((_) async => transaction);
      when(
        () => mockQuestList.findById('q-1'),
      ).thenReturn(_quest(status: QuestStatus.active));
      when(() => mockRepository.getTransaction('tx-1')).thenAnswer(
        (_) async => const StakeTransaction(
          transactionId: 'tx-1',
          status: 'pending',
        ),
      );

      final shortTopUpController = QuestPaymentController(
        mockRepository,
        mockQuestList,
        mockUrlOpener,
        'q-1',
        topUp: const StakeTopUp(amountXof: 1500),
        pollInterval: const Duration(milliseconds: 5),
        maxPollAttempts: 3,
      );

      await shortTopUpController.pay();
      await Future.delayed(const Duration(milliseconds: 60));

      expect(shortTopUpController.paymentTimedOut.value, isTrue);
      shortTopUpController.onClose();
    });
  });

  group('QuestPaymentController.onAppResumed', () {
    test('re-checks and resumes polling if not yet resolved', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => transaction);
      when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
      when(
        () => mockQuestList.findById('q-1'),
      ).thenReturn(_quest(status: QuestStatus.pendingPayment));

      await controller.pay();
      controller.stopPolling();

      await controller.onAppResumed();

      expect(controller.isPolling.value, isTrue);
      verify(() => mockQuestList.refreshQuest('q-1')).called(greaterThan(0));
      controller.stopPolling();
    });

    test('does nothing once payment already succeeded', () async {
      when(
        () => mockRepository.initiateStakePayment(
          'q-1',
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async => transaction);
      when(() => mockQuestList.refreshQuest('q-1')).thenAnswer((_) async {});
      when(
        () => mockQuestList.findById('q-1'),
      ).thenReturn(_quest(status: QuestStatus.active));

      await controller.pay();
      await controller.checkNow();
      expect(controller.paymentSucceeded.value, isTrue);
      clearInteractions(mockQuestList);

      await controller.onAppResumed();

      verifyNever(() => mockQuestList.refreshQuest(any()));
    });
  });
}
