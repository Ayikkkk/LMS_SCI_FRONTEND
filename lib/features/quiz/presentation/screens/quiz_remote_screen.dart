// lib/features/quiz/presentation/quiz_remote_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/quiz_notifier.dart';
import '../providers/quiz_provider.dart';
import 'quiz_view.dart';

class QuizRemoteScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const QuizRemoteScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  ConsumerState<QuizRemoteScreen> createState() =>
      _QuizRemoteScreenState();
}

class _QuizRemoteScreenState
    extends ConsumerState<QuizRemoteScreen> {
  bool started = false;

  @override
  void initState() {
    super.initState();

    // CEK STATUS QUIZ SAAT MASUK SCREEN
    Future.microtask(() {
      ref.read(quizNotifierProvider).loadQuiz(
            exerciseId: widget.exerciseId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(quizNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz"),
        centerTitle: true,
      ),
      body: started
          ? QuizView(exerciseId: widget.exerciseId)
          : _buildPreview(context, notifier),
    );
  }

  Widget _buildPreview(BuildContext context, QuizNotifier notifier) {
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
              alreadyDone
                  ? "Quiz sudah dikerjakan"
                  : "Quiz siap dimulai",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              alreadyDone
                  ? "Lihat hasil nilai quiz kamu"
                  : "Kerjakan quiz dengan sungguh-sungguh",
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            if (notifier.loading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 👉 Tidak perlu loadQuiz lagi
                    setState(() => started = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        alreadyDone ? Colors.green : null,
                  ),
                  child: Text(
                    alreadyDone ? "Lihat Nilai" : "Mulai Quiz",
                  ),
                ),
              ),

            if (notifier.error != null) ...[
              const SizedBox(height: 16),
              Text(
                notifier.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
