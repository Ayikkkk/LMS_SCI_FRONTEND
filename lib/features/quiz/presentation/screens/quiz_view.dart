// lib/features/quiz/presentation/quiz_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/quiz_notifier.dart';
import '../providers/quiz_provider.dart';

class QuizView extends ConsumerWidget {
  final String exerciseId;

  const QuizView({
    super.key,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(quizNotifierProvider);

    // LOADING STATE
    if (notifier.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // RESULT STATE
    if (notifier.submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hasil Quiz")),
        body: _buildResult(context, notifier),
      );
    }

    // EMPTY QUESTIONS
    if (notifier.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Soal belum tersedia", style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Berlangsung"),
        automaticallyImplyLeading: false, // cegah back default
      ),
      body: _buildQuestion(context, notifier),
    );
  }

  // ================= QUESTION VIEW =================
  Widget _buildQuestion(BuildContext context, QuizNotifier notifier) {
    final question = notifier.questions[notifier.currentIndex];

    final minutes = notifier.remainingSeconds ~/ 60;
    final seconds = notifier.remainingSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // TIMER
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.red.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sisa Waktu",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                "${minutes.toString().padLeft(2, '0')}:"
                "${seconds.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),

        // QUESTION TEXT
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Soal ${notifier.currentIndex + 1} / ${notifier.questions.length}\n\n"
            "${question.question}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),

        // ANSWER OPTIONS
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: question.options.map((opt) {
              final selected =
                  notifier.selectedAnswers[question.id] == opt.id;

              return Card(
                elevation: 2,
                child: ListTile(
                  leading: Radio<String>(
                    value: opt.id,
                    groupValue: notifier.selectedAnswers[question.id],
                    onChanged: (value) {
                      notifier.selectOption(question.id, value!);
                    },
                  ),
                  title: Text(opt.text),
                  tileColor: selected ? Colors.orange.shade50 : null,
                ),
              );
            }).toList(),
          ),
        ),

        // NAVIGATION BUTTONS
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (notifier.currentIndex > 0)
                ElevatedButton(
                  onPressed: notifier.previous,
                  child: const Text("Sebelumnya"),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: notifier.next,
                child: Text(
                  notifier.currentIndex == notifier.questions.length - 1
                      ? "Selesai"
                      : "Selanjutnya",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= RESULT VIEW =================
  Widget _buildResult(BuildContext context, QuizNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 90, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            "Hasil Quiz",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Nilai: ${notifier.finalScore}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Quiz hanya bisa dikerjakan sekali.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
