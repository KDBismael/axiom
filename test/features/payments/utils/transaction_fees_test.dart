import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/features/payments/utils/transaction_fees.dart';

void main() {
  group('calculateTransactionFees', () {
    test('combines the 4% rate with the 100 XOF flat fee', () {
      expect(calculateTransactionFees(1000), 140); // round(1000 * 0.04) + 100
    });

    test('rounds the percentage portion to the nearest XOF', () {
      expect(calculateTransactionFees(1250), 150); // round(1250 * 0.04 = 50) + 100
    });

    test('still applies the flat fee for a small stake', () {
      expect(calculateTransactionFees(200), 108); // round(200 * 0.04 = 8) + 100
    });
  });
}
