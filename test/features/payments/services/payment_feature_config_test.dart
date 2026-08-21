import 'package:axiom/features/payments/services/payment_feature_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is disabled by default', () {
    expect(
      const PaymentFeatureConfig(
        payInsEnabled: false,
        environment: 'disabled',
        sandboxVerified: false,
      ).isEnabled,
      isFalse,
    );
  });

  test('requires enabled, sandbox environment and verified provider facts', () {
    expect(
      const PaymentFeatureConfig(
        payInsEnabled: true,
        environment: 'sandbox',
        sandboxVerified: true,
      ).isEnabled,
      isTrue,
    );
    expect(
      const PaymentFeatureConfig(
        payInsEnabled: true,
        environment: 'production',
        sandboxVerified: true,
      ).isEnabled,
      isFalse,
    );
  });

  const sandboxCompile =
      bool.fromEnvironment('AXIOM_PAYINS_ENABLED') &&
      String.fromEnvironment('AXIOM_PAYMENT_ENV') == 'sandbox' &&
      bool.fromEnvironment('AXIOM_GENIUSPAY_SANDBOX_VERIFIED');
  test(
    'sandbox compilation enables the current feature configuration',
    () => expect(PaymentFeatureConfig.current.isEnabled, isTrue),
    skip: sandboxCompile ? false : 'Requires the sandbox Dart defines.',
  );
}
