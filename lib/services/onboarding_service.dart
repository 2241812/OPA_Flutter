import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Service for managing onboarding state via SharedPreferences.
class OnboardingService {
  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  /// Whether the user has completed onboarding.
  bool isOnboardingComplete() {
    return _prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
  }

  /// Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppConstants.onboardingCompleteKey, true);
  }

  /// Reset onboarding (useful for debug/dev).
  Future<void> resetOnboarding() async {
    await _prefs.remove(AppConstants.onboardingCompleteKey);
  }
}

/// Provider for the SharedPreferences instance (overridden in main.dart).
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden before use');
});

/// Provider for the onboarding service.
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return OnboardingService(prefs);
});
