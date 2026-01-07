// lib/features/quiz/presentation/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/quiz_view.dart';
import '../../../../navigation_service.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const QuizScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set current exercise ke NavigationService agar forceBackToQuiz bekerja
    NavigationService.instance.currentExerciseId = widget.exerciseId;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ====================================================
  // DETEKSI HOME / BACKGROUND -> PAKSA KEMBALI KE QUIZ
  // ====================================================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final nav = NavigationService.instance;

    if (!nav.isQuizLocked) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      Future.delayed(const Duration(milliseconds: 300), () {
        nav.forceBackToQuiz(); // TANPA PARAMETER
      });
    }
  }

  // ====================================================
  // POPUP WARNING KETIKA TEKAN BACK
  // ====================================================
  Future<void> _showWarningPopup() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          "Tidak Bisa Keluar!",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Anda harus menyelesaikan quiz sebelum keluar halaman ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Mengerti"),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // BACK BUTTON HANDLER
  // ====================================================
  Future<bool> _onWillPop() async {
    final nav = NavigationService.instance;
    final notifier = ref.read(quizNotifierProvider);

    // Jika quiz sudah selesai (submitted) → izinkan keluar
    if (notifier.submitted || !nav.isQuizLocked) {
      return true;
    }

    // Jika masih berlangsung → tampilkan warning
    await _showWarningPopup();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: QuizView(exerciseId: widget.exerciseId),
    );
  }
}
