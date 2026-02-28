import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/config/environment.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/version_service.dart';
import 'core/init/app_initializer.dart';
import 'core/theme/theme_notifier.dart';
import 'scaffold_messenger_key.dart';
import 'navigation_service.dart';

// SCREENS
import 'auth_redirector.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/course/presentation/screens/assignment_detail_screen.dart';
import 'core/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  EnvironmentConfig.initialize();

  // Print configuration in debug mode
  if (EnvironmentConfig.enableDebugFeatures) {
    EnvironmentConfig.printConfig();
  }

  // Initialize Firebase
  if (kDebugMode) {
    debugPrint('🔥 Initializing Firebase...');
  }
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint('✅ Firebase initialized successfully');
  }

  // Initialize Crashlytics
  await CrashlyticsService.initialize();

  // Initialize Analytics
  await AnalyticsService.initialize();

  // Initialize Version Service
  await VersionService.initialize();

  // Pass all uncaught errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await MediaStore.ensureInitialized();

  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ===========================================
  /// DETEKSI HOME BUTTON / APP KE BACKGROUND
  /// ===========================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final nav = NavigationService.instance;

    if (!nav.isQuizLocked) return;
    if (nav.currentExerciseId == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      Future.delayed(const Duration(milliseconds: 300), () {
        nav.forceBackToQuiz();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final init = ref.watch(appInitializerProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return AuthRedirector(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: EnvironmentConfig.getAppName('LMS Student'),
        themeMode: themeMode,
        theme: ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[50],
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[900],
          cardTheme: CardThemeData(
            elevation: 2,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            color: Colors.grey[850],
          ),
        ),
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorKey: NavigationService.instance.navigatorKey,
        home: init.when(
          loading: () => const SplashScreen(),
          error: (e, _) => _InitErrorView(error: e.toString()),
          data: (_) => const _RootPlaceholder(),
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/assignment/detail': (context) {
            final assignmentId =
                ModalRoute.of(context)!.settings.arguments as int;
            return AssignmentDetailScreen(
              assignmentId: assignmentId,
            );
          },
        },
      ),
    );
  }
}

// ======================
// ROOT PLACEHOLDER
// ======================
class _RootPlaceholder extends StatelessWidget {
  const _RootPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// ======================
// SPLASH & ERROR VIEW
// ======================
class _InitErrorView extends StatelessWidget {
  final String error;
  const _InitErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Init Error: $error',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
