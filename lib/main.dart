import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- Import Fitur Auth ---
import 'features/auth/data/repository/onboarding_repository.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/domain/auth_notifier.dart';
import 'features/auth/presentation/login_screen.dart';

// --- Import Fitur Home ---
import 'features/home/presentation/screens/home_screen.dart';

// 💡 PERUBAHAN: Jadikan main() async untuk memungkinkan pemanggilan await
void main() async {
  // Diperlukan oleh packages seperti shared_preferences/flutter_secure_storage
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('id_ID', null);
    print('Locale data for id_ID initialized successfully.');
  } catch (e) {
    // Menangani error jika gagal, agar aplikasi tetap bisa berjalan (walaupun mungkin format tanggalnya salah)
    print('FATAL ERROR: Failed to initialize locale data for id_ID: $e');
  }

  // agar semua widget dapat mengakses provider Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Cek Status Onboarding (FutureProvider)
    final onboardingStatus = ref.watch(onboardingStatusProvider);
    // 2. Cek Status Autentikasi (StateNotifierProvider)
    final authStatus = ref.watch(authNotifierProvider);

    Widget homeScreen;

    // Logika Navigasi Berdasarkan Onboarding Status
    homeScreen = onboardingStatus.when(
      // Selama loading data Onboarding dari SharedPreferences
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),

      // Jika terjadi error saat memuat Onboarding
      error: (err, stack) => Scaffold(
          body: Center(child: Text('Error memuat Onboarding: $err'))),

      // Jika data Onboarding sudah tersedia
      data: (hasSeenOnboarding) {
        if (!hasSeenOnboarding) {
          // Alur 1: Jika BELUM PERNAH lihat Onboarding
          return const OnboardingScreen();
        }

        // Alur 2: Jika SUDAH PERNAH lihat, lanjutkan ke pengecekan Login
        if (authStatus == AuthStatus.unknown) {
          // Status login masih dicek oleh AuthNotifier.checkAuthStatus()
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (authStatus == AuthStatus.authenticated) {
          // Sudah login, ke Home/Dashboard
          return const HomeScreen();
        } else {
          // Belum login, ke Login Screen
          return const LoginScreen();
        }
      },
    );

    return MaterialApp(
      title: 'LMS Student',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: homeScreen,
    );
  }
}