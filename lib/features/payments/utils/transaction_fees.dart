// GeniusPay's real cut (2.5% + 100 XOF flat) plus a 1.5% Axiom platform fee,
// combined into one number - shown to the user as a single "frais de
// transaction" line, never broken out between provider and platform. Mirrors
// calculateTransactionFees in the backend's src/payments/fees.ts exactly;
// the backend remains the source of truth for what's actually charged.
double calculateTransactionFees(double amountXof) {
  return (amountXof * 0.04).roundToDouble() + 100;
}
