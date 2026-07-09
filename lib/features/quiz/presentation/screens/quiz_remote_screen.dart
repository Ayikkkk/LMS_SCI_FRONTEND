// lib/features/quiz/presentation/quiz_remote_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quiz_notifier.dart';
import '../providers/quiz_provider.dart';
import '../../../../navigation_service.dart';
import '../../../../core/widgets/error_widget.dart';
import '../screens/quiz_screen.dart';
import '../../../auth/domain/auth_notifier.dart';

class QuizRemoteScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const QuizRemoteScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<QuizRemoteScreen> createState() => _QuizRemoteScreenState();
}

class _QuizRemoteScreenState extends ConsumerState<QuizRemoteScreen> {
  @override
  void initState() {
    super.initState();

    // Load quiz saat masuk screen — pass studentId untuk ownership pending submit
    Future.microtask(() {
      final studentId = ref.read(studentProvider)?.id.toString();
      ref.read(quizNotifierProvider).loadQuiz(
            exerciseId: widget.exerciseId,
            studentId: studentId,
          );
    });
  }

  // Cegah back saat sudah selesai quiz
  Future<bool> _onWillPop() async {
    final notifier = ref.read(quizNotifierProvider);

    // QUIZ SUDAH SELESAI → IZINKAN BACK
    if (notifier.submitted || notifier.alreadyDone) {
      return true;
    }

    // QUIZ BELUM DIMULAI → IZINKAN BACK
    if (!NavigationService.instance.isQuizLocked) {
      return true;
    }

    // QUIZ SEDANG BERLANGSUNG → BLOK BACK
    await _showWarningPopup();
    return false;
  }

  Future<void> _showWarningPopup() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tidak bisa keluar!"),
        content: const Text(
            "Anda harus menyelesaikan quiz sebelum keluar halaman ini."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Mengerti"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(quizNotifierProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final allowed = await _onWillPop();
        if (allowed && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Quiz"),
          centerTitle: true,
        ),
        body: _buildPreview(context, notifier),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, QuizNotifier notifier) {
    if (notifier.error != null && !notifier.loading) {
      return AppErrorWidget(
        message: notifier.error!,
        onRetry: () {
          final studentId = ref.read(studentProvider)?.id.toString();
          ref.read(quizNotifierProvider).loadQuiz(
                exerciseId: widget.exerciseId,
                studentId: studentId,
              );
        },
      );
    }

    final alreadyDone = notifier.alreadyDone;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              alreadyDone ? Icons.emoji_events : Icons.quiz,
              size: 90,
              color: alreadyDone ? Colors.green : Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              alreadyDone ? "Quiz sudah dikerjakan" : "Quiz siap dimulai",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              alreadyDone
                  ? "Lihat nilai quiz kamu"
                  : "Kerjakan quiz dengan jujur dan fokus",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            if (notifier.loading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    NavigationService.instance.runOrQueue((nav) {
                      nav.pushReplacement(
                        MaterialPageRoute(
                          settings:
                              RouteSettings(name: "quiz_${widget.exerciseId}"),
                          builder: (_) => QuizScreen(
                            exerciseId: widget.exerciseId,
                          ),
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        alreadyDone ? Colors.green : Colors.blueAccent,
                  ),
                  child: Text(
                    alreadyDone ? "Lihat Nilai" : "Mulai Quiz",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
