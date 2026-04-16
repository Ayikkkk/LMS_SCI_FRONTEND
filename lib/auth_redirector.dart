import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation_service.dart';
import 'features/auth/domain/auth_notifier.dart';
import 'features/auth/data/repository/onboarding_repository.dart';

class AuthRedirector extends ConsumerWidget {
  final Widget child;
  const AuthRedirector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pastikan navigation queue dieksekusi setelah navigator siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.instance.flushPending();
    });

    ref.listen<AuthStatus>(authNotifierProvider, (prev, next) {
      // Hanya proses jika status benar-benar berubah
      if (prev == next) return;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final navigator = NavigationService.instance.navigatorKey.currentState;
        if (navigator == null) return;

        // Cek onboarding dulu
        final hasSeenOnboarding =
            await ref.read(onboardingStatusProvider.future);

        if (!hasSeenOnboarding) {
          navigator.pushNamedAndRemoveUntil(
            '/onboarding',
            (route) => false,
          );
          return;
        }

        if (next == AuthStatus.authenticated) {
          navigator.pushNamedAndRemoveUntil('/home', (route) => false);
        } else if (next == AuthStatus.unauthenticated) {
          // Reset quiz lock state saat logout agar tidak ada sisa state
          NavigationService.instance.isQuizLocked = false;
          NavigationService.instance.currentExerciseId = null;

          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    });

    return child;
  }
}
