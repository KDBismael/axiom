import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axiom/core/services/onboarding_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingService', () {
    test('hasCompletedOnboarding defaults to false', () async {
      final service = OnboardingService();
      expect(await service.hasCompletedOnboarding(), isFalse);
    });

    test('hasCompletedOnboarding is true after markCompleted', () async {
      final service = OnboardingService();
      await service.markCompleted();
      expect(await service.hasCompletedOnboarding(), isTrue);
    });
  });
}
