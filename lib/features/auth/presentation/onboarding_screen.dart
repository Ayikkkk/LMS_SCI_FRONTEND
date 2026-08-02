//lib/features/auth/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/onboarding_repository.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  // Contoh data untuk slider
  static const List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding_1.png",
      "title": "Belajar Kapan Saja",
      "text": "Akses ribuan materi pelajaran dan tugas dari mana saja.",
    },
    // Tambahkan slide ke-2 dan ke-3 jika ada
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fungsi yang dipanggil saat user menekan tombol "Mulai"
    void finishOnboarding() async {
      // 1. Tandai bahwa Onboarding sudah dilihat
      await ref.read(onboardingRepositoryProvider).markOnboardingAsSeen();

      // 2. Paksa Riverpod untuk mengecek status Login lagi
      // Ini akan membawa user ke LoginScreen (karena authStatus menjadi unauthenticated)
      ref.invalidate(onboardingStatusProvider);

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Batasi tinggi gambar agar tidak overflow di HP pendek (< 600px)
            final imageHeight =
                (constraints.maxHeight * 0.35).clamp(150.0, 280.0);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Image.asset(
                        onboardingData[0]['image']!,
                        height: imageHeight,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        onboardingData[0]['title']!,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 189, 124, 245)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          onboardingData[0]['text']!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: finishOnboarding,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("MULAI"),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
