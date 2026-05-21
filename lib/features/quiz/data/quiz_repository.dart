// lib/features/quiz/data/quiz_repository.dart

/// Interface repository quiz (REAL, tanpa mock)
abstract class IQuizRepository {
  /// Ambil soal quiz
  /// Returns: Map dengan 'questions', 'exercise_type_name', dan 'time_limit_minutes' (nullable int, dalam menit)
  Future<Map<String, dynamic>> fetchQuiz({
    required String exerciseId,
  });

  /// Submit jawaban quiz
  ///
  /// [auto] digunakan untuk menandai apakah pengiriman dilakukan otomatis
  /// (misalnya karena waktu habis), agar backend bisa membedakan
  /// antara submit manual dan auto-submit.
  ///
  /// Returns: Map dengan 'is_pending_review' dan info lainnya
  Future<Map<String, dynamic>> submitQuiz({
    required String exerciseId,
    required Map<String, dynamic> answers,
    bool auto = false,
  });

  /// Ambil hasil quiz (jika sudah pernah mengerjakan)
  /// Returns: Map dengan 'score', 'is_pending_review', 'exercise_type_name'
  /// return null jika belum pernah
  Future<Map<String, dynamic>?> getResult({
    required String exerciseId,
  });

  /// Legacy method untuk backward compatibility
  @Deprecated('Use getResult() instead')
  Future<int?> getResultScore({
    required String exerciseId,
  }) async {
    final result = await getResult(exerciseId: exerciseId);
    return result?['score'];
  }
}
