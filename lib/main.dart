// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// PROVIDERS
import 'core/init/app_initializer.dart';
import 'features/auth/data/repository/onboarding_repository.dart';
import 'features/auth/domain/auth_notifier.dart';

// SCREENS
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

// Redirector
import 'auth_redirector.dart';

// Navigation service (navigatorKey)
import 'navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tunggu semua inisialisasi sebelum app benar-benar jalan
    final init = ref.watch(appInitializerProvider);

    return init.when(
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text("Init Error: $err")),
        ),
      ),
      data: (_) {
        return AuthRedirector(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LMS Student',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),

            // PENTING: pasang navigatorKey di sini
            navigatorKey: NavigationService.instance.navigatorKey,

            routes: {
              '/login': (_) => const LoginScreen(),
              '/home': (_) => const HomeScreen(),
              '/onboarding': (_) => const OnboardingScreen(),
            },

            home: _buildHomeByState(ref),
          ),
        );
      },
    );
  }

  Widget _buildHomeByState(WidgetRef ref) {
    final onboardingStatus = ref.watch(onboardingStatusProvider);
    final authStatus = ref.watch(authNotifierProvider);

    return onboardingStatus.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text("Error: $err")),
      ),
      data: (hasSeen) {
        if (!hasSeen) return const OnboardingScreen();

        if (authStatus == AuthStatus.unknown) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authStatus == AuthStatus.authenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
