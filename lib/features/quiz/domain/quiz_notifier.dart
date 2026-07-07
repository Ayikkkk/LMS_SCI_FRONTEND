import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../navigation_service.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/analytics_service.dart';
import '../data/quiz_repository.dart';
import '../data/quiz_log_service.dart';
import '../data/quiz_cache_service.dart';
import 'models/question_model.dart';

class QuizNotifier extends ChangeNotifier {
  final IQuizRepository repository;
  final QuizLogService? logService;
  final QuizCacheService? cacheService;

  QuizNotifier({
    required this.repository,
    this.logService,
    this.cacheService,
  });

  // Default waktu jika backend tidak set time_limit (dalam detik)
  static const int _defaultQuizSeconds = 60 * 60; // 60 menit

  // Sentinel: gunakan nilai ini untuk menandai "tidak ada batas waktu"
  static const int noTimeLimit = -1;

  late String _exerciseId;

  List<QuestionModel> _questions = [];
  List<QuestionModel> get questions => _questions;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  final Map<String, dynamic> _selectedAnswers = {};
  Map<String, dynamic> get selectedAnswers => _selectedAnswers;

  int? _finalScore;
  int? get finalScore => _finalScore;

  bool _isPendingReview = false;
  bool get isPendingReview => _isPendingReview;

  String? _exerciseTypeName;
  String? get exerciseTypeName => _exerciseTypeName;

  bool get alreadyDone => _finalScore != null || _isPendingReview;

  bool _submitted = false;
  bool get submitted => _submitted;

  Timer? _quizTimer;
  int _remainingSeconds = _defaultQuizSeconds;
  int get remainingSeconds => _remainingSeconds;

  // Total detik untuk sesi quiz ini (diset dari time_limit backend)
  int _totalQuizSeconds = _defaultQuizSeconds;
  int get totalQuizSeconds => _totalQuizSeconds;

  // Apakah ada submit yang pending (gagal karena network, menunggu retry)
  bool _hasPendingSubmit = false;
  bool get hasPendingSubmit => _hasPendingSubmit;

  // Flag untuk mencegah notifyListeners() setelah dispose()
  bool _disposed = false;

  // Timer debounce untuk _persistAnswers() — hanya dipakai oleh setTextAnswer()
  // Pilihan ganda, true/false, dll tidak butuh debounce karena jarang dipanggil
  Timer? _persistDebounce;

  // ============ QUIZ LOCK HANDLER ============
  void startQuizLock(String exerciseId) {
    NavigationService.instance.currentExerciseId = exerciseId;
    NavigationService.instance.isQuizLocked = true;
  }

  void endQuizLock() {
    NavigationService.instance.isQuizLocked = false;
    NavigationService.instance.currentExerciseId = null;
  }

  // ================= LOAD QUIZ =================
  Future<void> loadQuiz({required String exerciseId}) async {
    _exerciseId = exerciseId;

    _loading = true;
    _error = null;
    _submitted = false;
    _finalScore = null;
    _isPendingReview = false;
    _exerciseTypeName = null;
    _currentIndex = 0;
    _selectedAnswers.clear();
    _questions.clear();
    _quizTimer?.cancel();

    notifyListeners();

    try {
      // 🔍 Cek apakah sudah pernah dikerjakan
      final result = await repository.getResult(exerciseId: exerciseId);

      if (result != null) {
        _exerciseTypeName = result['exercise_type_name'];

        if (result['is_pending_review'] == true) {
          _isPendingReview = true;
          _submitted = true;
          _loading = false;
          endQuizLock();
          notifyListeners();
          return;
        }

        if (result['score'] != null) {
          _finalScore = result['score'];
          _submitted = true;
          _loading = false;
          endQuizLock();
          notifyListeners();
          return;
        }
      }

      // 🗄️ Cek memory cache dulu — skip network jika soal sudah ada
      final cached = cacheService?.getCachedQuestions(exerciseId);
      if (cached != null) {
        _questions = cached.questions;
        _exerciseTypeName = cached.exerciseTypeName;
        _setTimeLimit(cached.timeLimitMinutes);
        AppLogger.info('Quiz $exerciseId loaded from cache', 'QuizNotifier');
      } else {
        // 🧩 Fetch soal dari backend
        final quizData = await repository.fetchQuiz(exerciseId: exerciseId);
        _questions = quizData['questions'];
        _exerciseTypeName = quizData['exercise_type_name'];
        final timeLimitMinutes = quizData['time_limit_minutes'] as int?;
        _setTimeLimit(timeLimitMinutes);

        // Simpan ke cache untuk reconnect
        cacheService?.cacheQuestions(
          exerciseId: exerciseId,
          questions: _questions,
          exerciseTypeName: _exerciseTypeName,
          timeLimitMinutes: timeLimitMinutes,
        );
      }

      // 📝 Restore jawaban tersimpan (jika ada — misal setelah app crash)
      if (_questions.isNotEmpty) {
        final savedAnswers = await cacheService?.getSavedAnswers(exerciseId);
        if (savedAnswers != null && savedAnswers.isNotEmpty) {
          _selectedAnswers.addAll(savedAnswers);
          AppLogger.info(
              'Restored ${savedAnswers.length} saved answers for quiz $exerciseId',
              'QuizNotifier');
        }

        // 🔄 Cek apakah ada pending submit yang belum terkirim
        _hasPendingSubmit =
            await cacheService?.hasPendingSubmit(exerciseId) ?? false;
        if (_hasPendingSubmit) {
          AppLogger.warning(
              'Quiz $exerciseId has pending submit — will retry on submit',
              'QuizNotifier');
        }

        startQuizLock(exerciseId);
        _startGlobalTimer();
        logService?.logStart(exerciseId);

        await AnalyticsService.logQuizStart(
          quizId: exerciseId,
          quizName: _exerciseTypeName ?? 'Unknown',
          quizType: _exerciseTypeName ?? 'Unknown',
        );
      }
    } catch (e) {
      _error = ErrorMessages.fromException(e);
      AppLogger.error('loadQuiz failed', e, null, 'QuizNotifier');
    }

    _loading = false;
    notifyListeners();
  }

  // Helper: set time limit dari menit ke detik
  void _setTimeLimit(int? timeLimitMinutes) {
    _totalQuizSeconds =
        timeLimitMinutes != null ? timeLimitMinutes * 60 : noTimeLimit;
    _remainingSeconds = _totalQuizSeconds == noTimeLimit
        ? _defaultQuizSeconds
        : _totalQuizSeconds;
  }

  // ================= TIMER =================
  void _startGlobalTimer() {
    _quizTimer?.cancel();

    // Jika tidak ada batas waktu, tidak perlu jalankan timer countdown
    if (_totalQuizSeconds == noTimeLimit) return;

    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        timer.cancel();
        await submit(auto: true); // ⏱️ waktu habis → auto submit
        endQuizLock();
      }

      if (!_disposed) notifyListeners();
    });
  }

  // ================= ANSWER =================
  /// Select single option (for multiple choice, true/false, yes/no)
  void selectOption(String questionId, String optionId) {
    if (_submitted || alreadyDone) return;
    _selectedAnswers[questionId] = optionId;
    _persistAnswers();
    notifyListeners();
  }

  /// Toggle multiple options (for multiple answer questions)
  void toggleMultipleOption(String questionId, String optionId) {
    if (_submitted || alreadyDone) return;

    if (_selectedAnswers[questionId] is! List) {
      _selectedAnswers[questionId] = <String>[];
    }

    final List<String> selected =
        List<String>.from(_selectedAnswers[questionId] as List);

    if (selected.contains(optionId)) {
      selected.remove(optionId);
    } else {
      selected.add(optionId);
    }

    _selectedAnswers[questionId] = selected;
    _persistAnswers();
    notifyListeners();
  }

  /// Set text answer (for essay, short answer, fill in the blank)
  void setTextAnswer(String questionId, String text) {
    if (_submitted || alreadyDone) return;
    _selectedAnswers[questionId] = text;
    // Debounce 400ms — cegah write SharedPreferences setiap keystroke
    // Pilihan ganda tidak lewat sini sehingga tidak kena debounce
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!_disposed) _persistAnswers();
    });
    notifyListeners();
  }

  /// Simpan jawaban ke SharedPreferences (fire-and-forget, tidak block UI)
  void _persistAnswers() {
    cacheService?.saveAnswers(_exerciseId, Map.from(_selectedAnswers));
  }

  /// Flush debounce segera — pastikan jawaban terakhir tersimpan sebelum
  /// submit atau dispose. Dipanggil manual dari submit() dan dispose().
  void _flushPersist() {
    if (_persistDebounce?.isActive == true) {
      _persistDebounce!.cancel();
      _persistDebounce = null;
      _persistAnswers(); // simpan sekarang, jangan tunggu debounce
    }
  }

  /// Check if multiple option is selected
  bool isMultipleOptionSelected(String questionId, String optionId) {
    final answer = _selectedAnswers[questionId];
    if (answer is List) {
      return answer.contains(optionId);
    }
    return false;
  }

  /// Get text answer
  String getTextAnswer(String questionId) {
    final answer = _selectedAnswers[questionId];
    if (answer is String) {
      return answer;
    }
    return '';
  }

  // ================= VALIDATION =================
  bool get allAnswered {
    if (_questions.isEmpty) return false;
    return _questions.every((q) => _selectedAnswers.containsKey(q.id));
  }

  bool get canSubmit => allAnswered && !_submitted && !alreadyDone;

  // ================= NAVIGATION =================
  void next() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
    // Submit tidak dipanggil dari sini — UI (quiz_view) yang handle submit
    // agar tidak terjadi double submit
  }

  void previous() {
    if (_currentIndex == 0) return;
    _currentIndex--;
    notifyListeners();
  }

  // ================= SUBMIT =================
  Future<void> submit({bool auto = false, BuildContext? context}) async {
    // ============================================================
    // GUARD ATOMIK — set _submitted = true SEBELUM await pertama
    // Mencegah race condition: double tap, manual+auto bersamaan
    // ============================================================
    if (_submitted || alreadyDone) return;
    _submitted = true;
    notifyListeners(); // tombol submit langsung disable

    // Validasi hanya untuk submit manual
    if (!auto && !allAnswered) {
      _submitted = false; // rollback
      notifyListeners();
      AppLogger.warning(
          'Submit blocked: Not all questions answered', 'QuizNotifier');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Harap jawab semua pertanyaan dulu!")),
        );
      }
      return;
    }

    _quizTimer?.cancel();

    // Flush debounce — pastikan karakter terakhir essay tersimpan sebelum submit
    _flushPersist();

    // Snapshot jawaban sebelum submit — aman dari perubahan concurrent
    final answersSnapshot = Map<String, dynamic>.from(_selectedAnswers);

    try {
      // Retry untuk network/5xx error, TIDAK untuk 4xx (termasuk 403 sudah dikerjakan)
      final submitResult = await _submitWithRetry(
        exerciseId: _exerciseId,
        answers: answersSnapshot,
        auto: auto,
      );

      AppLogger.debug('Submit Result: $submitResult', 'QuizNotifier');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!_disposed) {
        if (submitResult['is_pending_review'] == true) {
          _isPendingReview = true;
          _finalScore = null;
        } else {
          // Wrap getResult() dalam try-catch: jika network blip setelah submit sukses,
          // jangan anggap seluruh submit gagal — fallback ke score dari response submit
          try {
            final result = await repository.getResult(exerciseId: _exerciseId);
            _finalScore = result?['score'] ?? submitResult['score'] ?? 0;
            _isPendingReview = result?['is_pending_review'] == true;
          } catch (e) {
            // getResult gagal tapi submit sudah sukses — pakai score dari submit response
            AppLogger.warning(
                'getResult failed after successful submit, using submit response score',
                'QuizNotifier');
            _finalScore = submitResult['score'] ?? 0;
            _isPendingReview = false;
          }
        }
      }

      // Submit berhasil — bersihkan cache
      await cacheService?.clearAnswers(_exerciseId);
      cacheService?.clearQuestionCache(_exerciseId);
      _hasPendingSubmit = false;
    } on _AlreadySubmittedException {
      // Backend return 403 "Quiz sudah pernah dikerjakan" — bukan error, load result
      AppLogger.info('Backend reports quiz already submitted — loading result',
          'QuizNotifier');
      try {
        final result = await repository.getResult(exerciseId: _exerciseId);
        if (!_disposed && result != null) {
          _finalScore = result['score'];
          _isPendingReview = result['is_pending_review'] == true;
          _exerciseTypeName = result['exercise_type_name'] ?? _exerciseTypeName;
        }
      } catch (_) {
        _finalScore = 0;
      }
      _hasPendingSubmit = false;
    } catch (e) {
      AppLogger.error('Submit failed after retries', e, null, 'QuizNotifier');

      // Simpan sebagai pending submit untuk retry saat network kembali
      await cacheService?.markPendingSubmit(_exerciseId, answersSnapshot, auto);
      _hasPendingSubmit = true;

      // Jangan tampilkan nilai 0 — biarkan score null agar UI tahu ini pending
      _finalScore = null;
      _isPendingReview = false;
    }

    endQuizLock();
    if (!_disposed) notifyListeners();

    final effectiveTotal = _totalQuizSeconds == noTimeLimit
        ? _defaultQuizSeconds
        : _totalQuizSeconds;
    final duration = effectiveTotal - _remainingSeconds;

    if (auto) {
      logService?.logAutoSubmit(_exerciseId, duration);
    } else {
      logService?.logSubmit(_exerciseId, duration);
    }

    if (auto) NavigationService.instance.navigateToHomeWhenReady();

    await AnalyticsService.logQuizComplete(
      quizId: _exerciseId,
      quizName: _exerciseTypeName ?? 'Unknown',
      quizType: _exerciseTypeName ?? 'Unknown',
      score: _finalScore,
      duration: duration,
      totalQuestions: _questions.length,
      answeredQuestions: _selectedAnswers.length,
    );
  }

  /// Submit dengan retry otomatis (max 3x, backoff 2s → 4s → 8s).
  /// Retry HANYA untuk network/5xx error.
  /// 4xx langsung rethrow — khususnya 403 dilempar sebagai _AlreadySubmittedException.
  Future<Map<String, dynamic>> _submitWithRetry({
    required String exerciseId,
    required Map<String, dynamic> answers,
    required bool auto,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    Duration delay = const Duration(seconds: 2);

    while (true) {
      try {
        return await repository.submitQuiz(
          exerciseId: exerciseId,
          answers: answers,
          auto: auto,
        );
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode ?? 0;

        // 403 khusus: backend menyatakan sudah pernah submit
        if (statusCode == 403) {
          throw _AlreadySubmittedException();
        }

        // Semua 4xx lain: client error, jangan retry
        if (statusCode >= 400 && statusCode < 500) {
          AppLogger.error('Submit rejected [$statusCode]: ${e.response?.data}',
              'QuizNotifier');
          rethrow;
        }

        // 5xx / network error: coba retry
        attempt++;
        if (attempt >= maxRetries) {
          AppLogger.error(
              'Submit attempt $attempt failed (max retries): ${e.message}',
              'QuizNotifier');
          rethrow;
        }

        AppLogger.warning(
            'Submit attempt $attempt failed [${statusCode > 0 ? statusCode : "network"}], '
                'retrying in ${delay.inSeconds}s...',
            'QuizNotifier');
        await Future.delayed(delay);
        delay *= 2; // exponential backoff: 2s → 4s → 8s
      } catch (e) {
        // Non-Dio exception: langsung rethrow, jangan retry
        rethrow;
      }
    }
  }

  // ================= RESET =================
  void reset() {
    _quizTimer?.cancel();
    _currentIndex = 0;
    _submitted = false;
    _finalScore = null;
    _selectedAnswers.clear();
    _hasPendingSubmit = false;
    _remainingSeconds = _totalQuizSeconds == noTimeLimit
        ? _defaultQuizSeconds
        : _totalQuizSeconds;

    startQuizLock(_exerciseId);
    _startGlobalTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _quizTimer?.cancel();
    // Flush debounce saat halaman ditutup — jawaban terakhir tidak hilang
    // meski timer belum selesai (misal user langsung close saat mengetik)
    _flushPersist();
    _persistDebounce?.cancel();
    super.dispose();
  }
}

/// Internal exception untuk membedakan 403 "sudah pernah submit"
/// dari 4xx error lainnya tanpa mengandalkan string matching.
class _AlreadySubmittedException implements Exception {
  const _AlreadySubmittedException();
}
