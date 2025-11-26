// lib/features/auth/data/repository/onboarding_repository.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _kOnboardingKey = 'has_seen_onboarding';

class OnboardingRepository {
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    // 💡 KEMBALIKAN KE LOGIKA NORMAL: Baca dari SharedPreferences
    return prefs.getBool(_kOnboardingKey) ?? false;
  }

  Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
  }
}

final onboardingRepositoryProvider = Provider((ref) => OnboardingRepository());

final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  return ref.watch(onboardingRepositoryProvider).hasSeenOnboarding();
});