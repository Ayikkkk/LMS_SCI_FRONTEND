import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/network/api_client.dart';

// Auth
import 'features/auth/data/repository/onboarding_repository.dart';
import 'features/auth/domain/auth_notifier.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';

// Home
import 'features/home/presentation/screens/home_screen.dart';

// Redirector
import 'auth_redirector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDioToken();

  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    print("Locale init gagal: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthRedirector(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LMS Student',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),

        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
        },

        home: _buildHomeByState(ref),
      ),
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
