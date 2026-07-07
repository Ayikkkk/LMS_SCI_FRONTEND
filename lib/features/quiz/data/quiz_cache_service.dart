// lib/features/quiz/data/quiz_cache_service.dart
//
// Cache ringan untuk kuis — mengatasi internet tidak stabil.
//
// Menyimpan dua hal:
//   1. Soal (questions + metadata) — in-memory, TTL 30 menit, max 10 entry
//   2. Jawaban sementara — persist ke SharedPreferences, aman dari app crash
//
// Alur:
//   loadQuiz → cek memory cache → kalau ada, pakai langsung (skip network)
//   selectAnswer → simpan ke SharedPreferences
//   submit berhasil → hapus cache jawaban
//   submit gagal → jawaban tetap tersimpan, bisa dicoba ulang
//   logout → bersihkan semua data SharedPreferences terkait kuis

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

  // Batas maksimal entry in-memory — cegah cache tumbuh tak terbatas
  // Nilai 10 cukup: rata-rata siswa tidak membuka lebih dari 10 kuis dalam
  // satu sesi tanpa menyelesaikannya
  static const int _maxCacheEntries = 10;

  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const String _answerPrefix = 'quiz_answers_';
  static const String _pendingSubmitPrefix = 'quiz_pending_submit_';
  // Key untuk menyimpan daftar exercise ID yang punya data di SharedPreferences
  // (digunakan saat clearAllUserData untuk bersihkan semua tanpa scan semua keys)
  static const String _trackedIdsKey = 'quiz_tracked_exercise_ids';

  // ════════════════════════════════════════════════════════════════════════
  // SOAL (in-memory)
  // ════════════════════════════════════════════════════════════════════════

  /// Simpan soal ke memory cache setelah berhasil di-fetch dari backend.
  /// Jika cache sudah penuh (>= _maxCacheEntries), hapus entry tertua dulu.
  void cacheQuestions({
    required String exerciseId,
    required List<QuestionModel> questions,
    required String? exerciseTypeName,
    required int? timeLimitMinutes,
  }) {
    // Evict entry tertua jika sudah penuh
    if (_questionCache.length >= _maxCacheEntries &&
        !_questionCache.containsKey(exerciseId)) {
      _evictOldest();
    }

    _questionCache[exerciseId] = CachedQuizData(
      questions: questions,
      exerciseTypeName: exerciseTypeName,
      timeLimitMinutes: timeLimitMinutes,
      cachedAt: DateTime.now(),
    );
    AppLogger.debug(
        'Quiz $exerciseId cached (${questions.length} questions, '
            'total cached: ${_questionCache.length}/$_maxCacheEntries)',
        'QuizCache');
  }

  /// Hapus entry yang paling lama di-cache (LRU sederhana — hapus yang cachedAt terlama).
  void _evictOldest() {
    if (_questionCache.isEmpty) return;

    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _questionCache.entries) {
      if (oldestTime == null || entry.value.cachedAt.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = entry.value.cachedAt;
      }
    }

    if (oldestKey != null) {
      _questionCache.remove(oldestKey);
      AppLogger.debug(
          'Evicted oldest quiz cache entry: $oldestKey', 'QuizCache');
    }
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

  /// Hapus semua in-memory cache — dipanggil saat logout.
  void clearAllQuestionCache() {
    _questionCache.clear();
    AppLogger.debug('All quiz question cache cleared (logout)', 'QuizCache');
  }

  // ════════════════════════════════════════════════════════════════════════
  // JAWABAN (SharedPreferences — persist ke disk)
  // ════════════════════════════════════════════════════════════════════════

  String _answerKey(String exerciseId) => '$_answerPrefix$exerciseId';
  String _pendingKey(String exerciseId) => '$_pendingSubmitPrefix$exerciseId';

  /// Simpan semua jawaban saat ini ke SharedPreferences.
  Future<void> saveAnswers(
      String exerciseId, Map<String, dynamic> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_answerKey(exerciseId), jsonEncode(answers));
      // Track exerciseId agar bisa di-clear saat logout
      await _trackExerciseId(prefs, exerciseId);
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
      await _untrackExerciseId(prefs, exerciseId);
    } catch (e) {
      AppLogger.warning('Failed to clear answers: $e', 'QuizCache');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PENDING SUBMIT
  // ════════════════════════════════════════════════════════════════════════

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
      await _trackExerciseId(prefs, exerciseId);
      AppLogger.warning(
          'Quiz $exerciseId submit pending (will retry on reconnect)',
          'QuizCache');
    } catch (e) {
      AppLogger.warning('Failed to mark pending submit: $e', 'QuizCache');
    }
  }

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

  Future<bool> hasPendingSubmit(String exerciseId) async {
    final pending = await getPendingSubmit(exerciseId);
    return pending != null;
  }

  // ════════════════════════════════════════════════════════════════════════
  // LOGOUT — bersihkan semua data quiz milik user yang sedang logout
  // Mencegah data jawaban siswa lama terbawa ke siswa baru di device yang sama
  // ════════════════════════════════════════════════════════════════════════

  /// Bersihkan semua data quiz dari SharedPreferences dan in-memory cache.
  /// Dipanggil dari AuthNotifier.doLogout().
  Future<void> clearAllUserData() async {
    // 1. Bersihkan in-memory cache soal
    clearAllQuestionCache();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 2. Ambil daftar exercise ID yang pernah di-track
      final tracked = _getTrackedIds(prefs);

      // 3. Hapus semua keys terkait kuis
      for (final id in tracked) {
        await prefs.remove(_answerKey(id));
        await prefs.remove(_pendingKey(id));
      }

      // 4. Hapus tracker itu sendiri
      await prefs.remove(_trackedIdsKey);

      AppLogger.info(
          'Cleared all quiz data for ${tracked.length} exercises on logout',
          'QuizCache');
    } catch (e) {
      AppLogger.warning('Failed to clear all user quiz data: $e', 'QuizCache');
    }
  }

  // ── Helpers untuk tracking exercise IDs ──────────────────────────────

  Set<String> _getTrackedIds(SharedPreferences prefs) {
    final raw = prefs.getString(_trackedIdsKey);
    if (raw == null) return {};
    try {
      return Set<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return {};
    }
  }

  Future<void> _trackExerciseId(SharedPreferences prefs, String id) async {
    final ids = _getTrackedIds(prefs)..add(id);
    await prefs.setString(_trackedIdsKey, jsonEncode(ids.toList()));
  }

  Future<void> _untrackExerciseId(SharedPreferences prefs, String id) async {
    final ids = _getTrackedIds(prefs)..remove(id);
    if (ids.isEmpty) {
      await prefs.remove(_trackedIdsKey);
    } else {
      await prefs.setString(_trackedIdsKey, jsonEncode(ids.toList()));
    }
  }
}
