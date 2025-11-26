import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/onboarding_repository.dart';
import '../domain/auth_notifier.dart';

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
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //
            // Placeholder untuk tampilan Gambar 2 (orangnya)
            // Di sini kamu bisa gunakan PageView.builder untuk membuat slider
            Image.asset(
              onboardingData[0]['image']!,
              height: 300,
            ),
            const SizedBox(height: 30),
            Text(
              onboardingData[0]['title']!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 189, 124, 245)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                onboardingData[0]['text']!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: finishOnboarding,
              child: const Text("MULAI"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}