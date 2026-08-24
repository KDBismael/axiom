import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/onboarding_service.dart';

/// Drives the 3-slide swipeable intro: tracks the visible slide, advances it,
/// and persists completion (via [OnboardingService]) so onboarding never
/// shows again. Navigation after completion is the view's responsibility
/// (same split as [QuestCreateController]/`quest_create_view.dart`).
class OnboardingController extends GetxController {
  OnboardingController({OnboardingService? onboardingService})
    : _onboardingService = onboardingService ?? OnboardingService();

  final OnboardingService _onboardingService;

  static const slideCount = 3;

  final currentPage = 0.obs;
  final pageController = PageController();

  bool get isLastPage => currentPage.value == slideCount - 1;

  /// Called by the PageView's `onPageChanged` when the user swipes manually.
  void onPageChanged(int index) {
    currentPage.value = index;
  }

  /// Advances to the next slide; a no-op on the last slide.
  Future<void> advance() async {
    if (isLastPage) return;
    currentPage.value += 1;
    if (pageController.hasClients) {
      await pageController.animateToPage(
        currentPage.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Persists onboarding completion; the caller navigates afterward.
  Future<void> complete() => _onboardingService.markCompleted();

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
