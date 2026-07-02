import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed the onboarding screen, so it only
/// shows once (persisted across app launches).
class OnboardingService {
  static const _completedKey = 'onboarding_completed';

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
