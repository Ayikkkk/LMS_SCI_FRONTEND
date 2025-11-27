import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/domain/auth_notifier.dart';

class AuthRedirector extends ConsumerWidget {
  final Widget child;
  const AuthRedirector({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthStatus>(authNotifierProvider, (prev, next) {
      // Redirect setelah frame selesai dirender
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (next == AuthStatus.authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
        else if (next == AuthStatus.unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      });
    });

    return child;
  }
}
