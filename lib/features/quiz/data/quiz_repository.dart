// lib/features/quiz/data/quiz_repository.dart

import '../domain/models/question_model.dart';

/// Interface repository quiz (REAL, tanpa mock)
abstract class IQuizRepository {
  /// Ambil soal quiz
  Future<List<QuestionModel>> fetchQuiz({
    required String exerciseId,
  });

  /// Submit jawaban quiz
  ///
  /// [auto] digunakan untuk menandai apakah pengiriman dilakukan otomatis
  /// (misalnya karena waktu habis), agar backend bisa membedakan
  /// antara submit manual dan auto-submit.
  Future<void> submitQuiz({
    required String exerciseId,
    required Map<String, String> answers,
    bool auto = false, // ✅ ditambahkan di sini
  });

  /// Ambil hasil quiz (jika sudah pernah mengerjakan)
  /// return null jika belum pernah
  Future<int?> getResultScore({
    required String exerciseId,
  });
}
