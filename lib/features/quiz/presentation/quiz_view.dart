import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quiz_notifier.dart';
import 'providers/quiz_provider.dart';

class QuizView extends ConsumerWidget {
  const QuizView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(quizNotifierProvider);

    if (notifier.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifier.error != null) {
      return Center(child: Text("Error: ${notifier.error}"));
    }

    if (notifier.questions.isEmpty) {
      return const Center(
        child: Text("Tidak ada soal untuk quiz ini."),
      );
    }

    if (notifier.submitted) {
      return _buildResult(context, notifier);
    }

    return _buildQuestion(context, ref, notifier);
  }

  Widget _buildResult(BuildContext context, QuizNotifier notifier) {
    final total = notifier.questions.length;
    final score = notifier.score;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            "Nilai Kamu",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            "$score / $total",
            style: const TextStyle(
              fontSize: 32,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: notifier.reset,
            child: const Text("Ulangi Quiz"),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
      BuildContext context, WidgetRef ref, QuizNotifier notifier) {
    final q = notifier.questions[notifier.currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TIMER
        if (q.timeLimitSeconds != null && q.timeLimitSeconds! > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Text(
              "Sisa Waktu: ${notifier.remainingSeconds} detik",
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),

        // SOAL
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "${notifier.currentIndex + 1}. ${q.question}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),

        // OPSI JAWABAN
        Expanded(
          child: ListView(
            children: q.options.map((opt) {
              final bool selected =
                  notifier.selectedAnswers[q.id] == opt.id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(opt.text),
                  leading: Radio<String>(
                    value: opt.id,
                    groupValue: notifier.selectedAnswers[q.id],
                    onChanged: (val) {
                      notifier.selectOption(q.id, opt.id);
                    },
                  ),
                  tileColor:
                      selected ? Colors.blue.shade50 : Colors.white,
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
                onPressed: () {
                  notifier.next();
                },
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
}
