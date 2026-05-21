// lib/features/quiz/data/quiz_cache_service.dart
//
// Cache ringan untuk kuis — mengatasi internet tidak stabil.
//
// Menyimpan dua hal:
//   1. Soal (questions + metadata) — in-memory, hilang saat app di-kill (wajar,
//      soal di-shuffle tiap request jadi tidak perlu persist ke disk)
//   2. Jawaban sementara — di-persist ke SharedPreferences, aman dari app crash
//
// Alur:
//   loadQuiz → cek memory cache → kalau ada, pakai langsung (skip network)
//   selectAnswer → simpan ke SharedPreferences
//   submit berhasil → hapus cache jawaban
//   submit gagal → jawaban tetap tersimpan, bisa dicoba ulang

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';
import '../domain/models/question_model.dart';

final quizCacheServiceProvider = Provider<QuizCacheService>((ref) {
  return QuizCacheService();
});

class CachedQuizData {
  final List<QuestionModel> questions;
  final String? exerciseTypeName;
  final int? timeLimitMinutes;
  final DateTime cachedAt;

  CachedQuizData({
    required this.questions,
    required this.exerciseTypeName,
    required this.timeLimitMinutes,
    required this.cachedAt,
  });

  // Cache soal dianggap valid selama 30 menit
  bool get isValid => DateTime.now().difference(cachedAt).inMinutes < 30;
}

class QuizCacheService {
  // ── In-memory cache untuk soal ──────────────────────────────────────────
  final Map<String, CachedQuizData> _questionCache = {};

  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const String _answerPrefix = 'quiz_answers_';
  static const String _pendingSubmitPrefix = 'quiz_pending_submit_';

  // ════════════════════════════════════════════════════════════════════════
  // SOAL (in-memory)
  // ════════════════════════════════════════════════════════════════════════

  /// Simpan soal ke memory cache setelah berhasil di-fetch dari backend.
  void cacheQuestions({
    required String exerciseId,
    required List<QuestionModel> questions,
    required String? exerciseTypeName,
    required int? timeLimitMinutes,
  }) {
    _questionCache[exerciseId] = CachedQuizData(
      questions: questions,
      exerciseTypeName: exerciseTypeName,
      timeLimitMinutes: timeLimitMinutes,
      cachedAt: DateTime.now(),
    );
    AppLogger.debug(
        'Quiz $exerciseId cached (${questions.length} questions)', 'QuizCache');
  }

  /// Ambil soal dari cache. Return null jika tidak ada atau sudah expired.
  CachedQuizData? getCachedQuestions(String exerciseId) {
    final cached = _questionCache[exerciseId];
    if (cached == null) return null;
    if (!cached.isValid) {
      _questionCache.remove(exerciseId);
      AppLogger.debug('Quiz $exerciseId cache expired', 'QuizCache');
      return null;
    }
    AppLogger.debug(
        'Quiz $exerciseId loaded from cache (${cached.questions.length} questions)',
        'QuizCache');
    return cached;
  }

  /// Hapus cache soal (misal setelah submit berhasil).
  void clearQuestionCache(String exerciseId) {
    _questionCache.remove(exerciseId);
  }

  // ════════════════════════════════════════════════════════════════════════
  // JAWABAN (SharedPreferences — persist ke disk)
  // ════════════════════════════════════════════════════════════════════════

  String _answerKey(String exerciseId) => '$_answerPrefix$exerciseId';
  String _pendingKey(String exerciseId) => '$_pendingSubmitPrefix$exerciseId';

  /// Simpan semua jawaban saat ini ke SharedPreferences.
  /// Dipanggil setiap kali siswa menjawab satu soal.
  Future<void> saveAnswers(
      String exerciseId, Map<String, dynamic> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_answerKey(exerciseId), jsonEncode(answers));
    } catch (e) {
      AppLogger.warning('Failed to save answers: $e', 'QuizCache');
    }
  }

  /// Ambil jawaban yang tersimpan. Return null jika tidak ada.
  Future<Map<String, dynamic>?> getSavedAnswers(String exerciseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_answerKey(exerciseId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      AppLogger.debug(
          'Restored ${decoded.length} saved answers for quiz $exerciseId',
          'QuizCache');
      return decoded;
    } catch (e) {
      AppLogger.warning('Failed to restore answers: $e', 'QuizCache');
      return null;
    }
  }

  /// Hapus jawaban tersimpan setelah submit berhasil.
  Future<void> clearAnswers(String exerciseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_answerKey(exerciseId));
      await prefs.remove(_pendingKey(exerciseId));
    } catch (e) {
      AppLogger.warning('Failed to clear answers: $e', 'QuizCache');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PENDING SUBMIT (submit gagal karena network, simpan untuk retry)
  // ════════════════════════════════════════════════════════════════════════

  /// Tandai bahwa ada submit yang pending (gagal karena network).
  Future<void> markPendingSubmit(
      String exerciseId, Map<String, dynamic> answers, bool auto) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _pendingKey(exerciseId),
        jsonEncode({
          'answers': answers,
          'auto': auto,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      AppLogger.warning(
          'Quiz $exerciseId submit pending (will retry on reconnect)',
          'QuizCache');
    } catch (e) {
      AppLogger.warning('Failed to mark pending submit: $e', 'QuizCache');
    }
  }

  /// Ambil data pending submit jika ada.
  Future<Map<String, dynamic>?> getPendingSubmit(String exerciseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_pendingKey(exerciseId));
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Cek apakah ada pending submit untuk exercise ini.
  Future<bool> hasPendingSubmit(String exerciseId) async {
    final pending = await getPendingSubmit(exerciseId);
    return pending != null;
  }
}
