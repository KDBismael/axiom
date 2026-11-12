import 'dart:math' as math;

/// A random 128-bit hex key for the backend's `Idempotency-Key` header —
/// generate one per user intent (one form, one tap), reuse it on retries.
String newIdempotencyKey() {
  final random = math.Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
