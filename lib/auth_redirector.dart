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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        NavigationService.instance.runOrQueue((nav) async {
          // 1 CEK ONBOARDING
          final hasSeenOnboarding =
              await ref.read(onboardingStatusProvider.future);

          if (!hasSeenOnboarding) {
            nav.pushNamedAndRemoveUntil(
              '/onboarding',
              (route) => false,
            );
            return;
          }

          // 2️ BARU CEK AUTH
          if (next == AuthStatus.authenticated) {
            nav.pushNamedAndRemoveUntil('/home', (route) => false);
          } else if (next == AuthStatus.unauthenticated) {
            nav.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      });
    });

    return child;
  }
}
