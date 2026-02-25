// lib/features/quiz/presentation/quiz_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/quiz_notifier.dart';
import '../../domain/models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../widgets/question_widgets.dart';

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

    // QUIZ SCREEN
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Berlangsung"),
        automaticallyImplyLeading: false, // cegah back default
      ),
      body: _buildQuestion(context, notifier, ref),
    );
  }

  // ================= QUESTION VIEW =================
  Widget _buildQuestion(
      BuildContext context, QuizNotifier notifier, WidgetRef ref) {
    final question = notifier.questions[notifier.currentIndex];
    final minutes = notifier.remainingSeconds ~/ 60;
    final seconds = notifier.remainingSeconds % 60;

    final answered = notifier.selectedAnswers.containsKey(question.id);

    //  Jika waktu habis tapi hasil belum tampil (auto-submit sedang jalan)
    if (notifier.remainingSeconds <= 0 && !notifier.submitted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Waktu habis!\nMengirim hasil kuis...",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

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
                "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: notifier.remainingSeconds <= 10
                      ? Colors.red
                      : Colors.black87,
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
          child: _buildQuestionWidget(question, notifier),
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
                  //  Logika navigasi + validasi wajib jawab
                  if (notifier.currentIndex == notifier.questions.length - 1) {
                    // Jika di soal terakhir, cek apakah semua sudah dijawab
                    if (notifier.allAnswered) {
                      notifier.submit(context: context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Harap jawab semua pertanyaan sebelum menyelesaikan kuis."),
                        ),
                      );
                    }
                  } else {
                    // Kalau belum di soal terakhir, pastikan sudah jawab soal ini
                    if (!answered) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Harap pilih jawaban terlebih dahulu."),
                        ),
                      );
                      return;
                    }
                    notifier.next();
                  }
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

  // ================= RESULT VIEW =================
  Widget _buildResult(BuildContext context, QuizNotifier notifier) {
    // Jika pending review (menunggu penilaian guru)
    if (notifier.isPendingReview) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pending_actions, size: 90, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              "Quiz Terkirim",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Menunggu Penilaian Guru",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Jawaban Anda sedang ditinjau oleh guru. Nilai akan muncul setelah guru selesai menilai.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            if (notifier.exerciseTypeName != null) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tipe: ${notifier.exerciseTypeName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Jika sudah ada nilai
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
          if (notifier.exerciseTypeName != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tipe: ${notifier.exerciseTypeName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= QUESTION WIDGET BUILDER =================
  Widget _buildQuestionWidget(QuestionModel question, QuizNotifier notifier) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceWidget(question: question, notifier: notifier);

      case QuestionType.multipleAnswer:
        return MultipleAnswerWidget(question: question, notifier: notifier);

      case QuestionType.trueFalse:
        return TrueFalseWidget(question: question, notifier: notifier);

      case QuestionType.yesNo:
        return YesNoWidget(question: question, notifier: notifier);

      case QuestionType.shortAnswer:
      case QuestionType.fillInTheBlank:
        return ShortAnswerWidget(question: question, notifier: notifier);

      case QuestionType.essay:
        return EssayWidget(question: question, notifier: notifier);
    }
  }
}
