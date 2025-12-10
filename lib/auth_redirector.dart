// lib/auth_redirector.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'navigation_service.dart';
import 'features/auth/domain/auth_notifier.dart';

class AuthRedirector extends ConsumerWidget {
  final Widget child;
  const AuthRedirector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flush pending navigation attempts whenever this widget is built
    // (ensures navigation will run once MaterialApp+navigatorKey siap).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.instance.flushPending();
    });

    ref.listen<AuthStatus>(authNotifierProvider, (prev, next) {
      if (prev == next) return;

      // Queue or run navigation after current frame to keep it safe.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationService.instance.runOrQueue((nav) {
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
