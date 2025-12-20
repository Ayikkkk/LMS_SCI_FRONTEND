// lib/features/quiz/data/quiz_repository.dart
import '../domain/models/question_model.dart';

/// Interface repository quiz (REAL, tanpa mock)
abstract class IQuizRepository {
  /// Ambil soal quiz
  Future<List<QuestionModel>> fetchQuiz({
    required String exerciseId,
  });

  /// Submit jawaban quiz
  Future<void> submitQuiz({
    required String exerciseId,
    required Map<String, String> answers,
  });

  /// Ambil hasil quiz (jika sudah pernah mengerjakan)
  /// return null jika belum pernah
  Future<int?> getResultScore({
    required String exerciseId,
  });
}
