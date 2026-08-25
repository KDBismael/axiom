import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/api/api_client.dart';
import 'package:axiom/features/quests/models/quest_model.dart';
import 'package:axiom/features/payments/repositories/payment_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late PaymentRepository repository;

  final transactionJson = {
    'transactionId': 'tx-1',
    'questId': 'q-1',
    'geniusReference': 'MTX-ABC',
    'paymentUrl': 'https://wave.com/pay/abc',
    'status': 'pending',
    'amountXof': 1500,
    'feesXof': null,
  };

  setUp(() {
    mockClient = MockApiClient();
    repository = PaymentRepository(mockClient);
  });

  group('PaymentRepository.initiateStakePayment', () {
    test('POSTs just the phone number for the default (no top-up) flow', () async {
      when(() => mockClient.post('/quests/q-1/stake/pay', {})).thenAnswer(
        (_) async => Response(statusCode: 200, body: transactionJson),
      );

      final result = await repository.initiateStakePayment('q-1');

      expect(result.transactionId, 'tx-1');
    });

    test('includes additionalAmountXof and fundsDistribution for a top-up', () async {
      when(
        () => mockClient.post('/quests/q-1/stake/pay', {
          'additionalAmountXof': 1500.0,
          'fundsDistribution': 'charity',
        }),
      ).thenAnswer(
        (_) async => Response(statusCode: 200, body: transactionJson),
      );

      final result = await repository.initiateStakePayment(
        'q-1',
        additionalAmountXof: 1500,
        fundsDistribution: FundsDistribution.charity,
      );

      expect(result.transactionId, 'tx-1');
    });

    test('throws PaymentException with the backend message on failure', () async {
      when(() => mockClient.post('/quests/q-1/stake/pay', {})).thenAnswer(
        (_) async => const Response(
          statusCode: 400,
          body: {'message': "Cette quête n'accepte pas de paiement pour le moment"},
        ),
      );

      expect(
        () => repository.initiateStakePayment('q-1'),
        throwsA(
          isA<PaymentException>().having(
            (e) => e.message,
            'message',
            "Cette quête n'accepte pas de paiement pour le moment",
          ),
        ),
      );
    });
  });

  group('PaymentRepository.getTransaction', () {
    test('GETs the transaction by id and returns it parsed', () async {
      when(() => mockClient.get<dynamic>('/payments/transactions/tx-1'))
          .thenAnswer(
            (_) async => Response(statusCode: 200, body: transactionJson),
          );

      final result = await repository.getTransaction('tx-1');

      expect(result.transactionId, 'tx-1');
      expect(result.status, 'pending');
    });

    test('throws PaymentException when the transaction is not found', () async {
      when(() => mockClient.get<dynamic>('/payments/transactions/nope'))
          .thenAnswer(
            (_) async => const Response(
              statusCode: 404,
              body: {'message': 'Transaction introuvable'},
            ),
          );

      expect(
        () => repository.getTransaction('nope'),
        throwsA(isA<PaymentException>()),
      );
    });
  });
}
