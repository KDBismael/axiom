class PaymentFeatureConfig {
  const PaymentFeatureConfig({
    this.payInsEnabled = const bool.fromEnvironment(
      'AXIOM_PAYINS_ENABLED',
      defaultValue: false,
    ),
    this.environment = const String.fromEnvironment(
      'AXIOM_PAYMENT_ENV',
      defaultValue: 'disabled',
    ),
    this.sandboxVerified = const bool.fromEnvironment(
      'AXIOM_GENIUSPAY_SANDBOX_VERIFIED',
      defaultValue: false,
    ),
  });

  final bool payInsEnabled;
  final String environment;
  final bool sandboxVerified;

  bool get isEnabled =>
      payInsEnabled && environment == 'sandbox' && sandboxVerified;

  static const current = PaymentFeatureConfig();
}
