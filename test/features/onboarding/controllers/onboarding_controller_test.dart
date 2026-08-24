import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/core/services/onboarding_service.dart';
import 'package:axiom/features/onboarding/controllers/onboarding_controller.dart';

class MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  late MockOnboardingService mockService;
  late OnboardingController controller;

  setUp(() {
    mockService = MockOnboardingService();
    when(() => mockService.markCompleted()).thenAnswer((_) async {});
    controller = OnboardingController(onboardingService: mockService);
  });

  tearDown(() {
    controller.onClose();
  });

  group('OnboardingController.advance', () {
    test('moves from the first slide to the second', () async {
      await controller.advance();
      expect(controller.currentPage.value, 1);
    });

    test('moves from the second slide to the third (last)', () async {
      controller.currentPage.value = 1;
      await controller.advance();
      expect(controller.currentPage.value, 2);
      expect(controller.isLastPage, isTrue);
    });

    test('is a no-op on the last slide', () async {
      controller.currentPage.value = OnboardingController.slideCount - 1;
      await controller.advance();
      expect(controller.currentPage.value, OnboardingController.slideCount - 1);
    });
  });

  group('OnboardingController.complete', () {
    test('persists onboarding completion', () async {
      await controller.complete();
      verify(() => mockService.markCompleted()).called(1);
    });
  });

  group('OnboardingController.onPageChanged', () {
    test('mirrors manual swipes into currentPage', () {
      controller.onPageChanged(2);
      expect(controller.currentPage.value, 2);
    });
  });

  group('OnboardingController.isLastPage', () {
    test('is true only on the final slide index', () {
      controller.currentPage.value = 0;
      expect(controller.isLastPage, isFalse);
      controller.currentPage.value = OnboardingController.slideCount - 1;
      expect(controller.isLastPage, isTrue);
    });
  });
}
