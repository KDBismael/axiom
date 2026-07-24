import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/payments/models/stake_transaction.dart';

void main() {
  group('StakeTransaction.fromJson', () {
    test('parses all fields', () {
      final json = {
        'transactionId': 'tx-1',
        'geniusReference': 'MTX-ABC',
        'paymentUrl': 'https://wave.com/pay/abc',
        'status': 'pending',
        'amountXof': 5000,
        'feesXof': 150,
      };

      final tx = StakeTransaction.fromJson(json);

      expect(tx.transactionId, 'tx-1');
      expect(tx.geniusReference, 'MTX-ABC');
      expect(tx.paymentUrl, 'https://wave.com/pay/abc');
      expect(tx.status, 'pending');
      expect(tx.amountXof, 5000);
      expect(tx.feesXof, 150);
    });

    test('accepts Decimal fields serialized as strings', () {
      final json = {
        'transactionId': 'tx-2',
        'geniusReference': null,
        'paymentUrl': null,
        'status': 'pending',
        'amountXof': '5000',
        'feesXof': null,
      };

      final tx = StakeTransaction.fromJson(json);

      expect(tx.amountXof, 5000);
      expect(tx.feesXof, isNull);
      expect(tx.geniusReference, isNull);
      expect(tx.paymentUrl, isNull);
    });
  });
}
