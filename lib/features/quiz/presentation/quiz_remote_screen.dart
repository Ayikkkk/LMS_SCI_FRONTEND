// lib/features/quiz/presentation/quiz_remote_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quiz_notifier.dart';
import 'quiz_view.dart';
import 'providers/quiz_provider.dart';

class QuizRemoteScreen extends ConsumerStatefulWidget {
  final String exerciseId;

  const QuizRemoteScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<QuizRemoteScreen> createState() => _QuizRemoteScreenState();
}

class _QuizRemoteScreenState extends ConsumerState<QuizRemoteScreen> {
  bool started = false;
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    // Mengamati QuizNotifier agar UI bereaksi terhadap perubahan (loading, error, dsb.)
    final notifier = ref.watch(quizNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Mulai Quiz")),
      body: started
          ? const QuizView() // tampil soal (QuizView diharapkan membaca quizNotifierProvider)
          : _buildPreview(context, notifier),
    );
  }

  Widget _buildPreview(BuildContext context, QuizNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text("Kuis Siap Dimulai!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Jika sedang memulai (memuat soal), tampilkan progress
          if (_starting || notifier.loading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Memuat soal...'),
          ] else ...[
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _starting = true;
                });

                try {
                  // PERUBAHAN PENTING: pakai nama parameter exerciseId (bukan quizId)
                  await notifier.loadQuiz(exerciseId: widget.exerciseId);
                  // baru setelah berhasil memuat soal, tampilkan QuizView
                  setState(() {
                    started = true;
                  });
                } catch (e) {
                  // jika ada error, notifier.error akan diisi; kita juga hentikan loading local
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memuat soal: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _starting = false;
                    });
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text("Mulai"),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Tampilkan pesan error jika ada
          if (notifier.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: Text(
                notifier.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
