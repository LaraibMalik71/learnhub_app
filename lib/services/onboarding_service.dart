import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';

  // Check whether the user has completed onboarding.
  Future<bool> isOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_onboardingKey) ?? false;
  }

  // Save onboarding completion.
  Future<void> completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_onboardingKey, true);
  }
}
