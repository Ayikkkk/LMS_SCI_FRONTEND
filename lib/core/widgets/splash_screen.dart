import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../init/app_initializer.dart';
import '../services/version_service.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/data/repository/onboarding_repository.dart';
import '../../navigation_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Jalankan init + minimum duration secara paralel
    _startAndNavigate();
  }

  Future<void> _startAndNavigate() async {
    // Tunggu keduanya: init app selesai DAN minimum 2.5 detik
    await Future.wait([
      // Trigger dan tunggu appInitializerProvider — tidak akan throw karena sudah di-handle
      ref.read(appInitializerProvider.future).catchError((_) {}),
      // Minimum splash duration
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    if (!mounted || _navigated) return;
    _navigated = true;

    final navigator = NavigationService.instance.navigatorKey.currentState;
    if (navigator == null) return;

    final hasSeenOnboarding = await ref.read(onboardingStatusProvider.future);
    if (!mounted) return;

    final authStatus = ref.read(authNotifierProvider);

    if (!hasSeenOnboarding) {
      navigator.pushNamedAndRemoveUntil('/onboarding', (_) => false);
    } else if (authStatus == AuthStatus.authenticated) {
      navigator.pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      navigator.pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final version = VersionService.currentVersion;
    final build = VersionService.buildNumber;

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo dan teks di tengah ────────────────────────
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/Logosci2.jpg',
                            width: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'SCIMEDIA-ONLINE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Pembelajaran SD/MI Berbasis Teknologi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Nama app & versi di bawah dengan background gelap ───
            FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCI Media Online',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white70),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'V. $version - B.N. $build',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
