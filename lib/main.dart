// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'scaffold_messenger_key.dart';

// INIT
import 'core/init/app_initializer.dart';
import 'package:timeago/timeago.dart' as timeago;

// PROVIDERS
import 'features/auth/data/repository/onboarding_repository.dart';
import 'features/auth/domain/auth_notifier.dart';

// SCREENS
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

// Redirect Middleware
import 'auth_redirector.dart';

// Navigation service
import 'navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Set bahasa Indonesia untuk timeago
  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(appInitializerProvider);

    return init.when(
      loading: () => const _AppLoadingView(),
      error: (err, _) => _InitErrorView(error: err.toString()),

      data: (_) => AuthRedirector(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LMS Student',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
            useMaterial3: true,
          ),
          scaffoldMessengerKey: scaffoldMessengerKey,
          navigatorKey: NavigationService.instance.navigatorKey,
          home: _buildHomeByState(ref),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const HomeScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
          },
        ),
      ),
    );
  }

  Widget _buildHomeByState(WidgetRef ref) {
    final onboardingStatus = ref.watch(onboardingStatusProvider);
    final authStatus = ref.watch(authNotifierProvider);

    return onboardingStatus.when(
      loading: () => const _AppLoadingView(),
      error: (err, _) => _InitErrorView(error: err.toString()),

      data: (hasSeen) {
        if (!hasSeen) return const OnboardingScreen();

        switch (authStatus) {
          case AuthStatus.authenticated:
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          default:
            return const _AppLoadingView();
        }
      },
    );
  }
}

// ======================
// UI LOADING & ERROR
// ======================

class _AppLoadingView extends StatelessWidget {
  const _AppLoadingView();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _InitErrorView extends StatelessWidget {
  final String error;
  const _InitErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Init Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
