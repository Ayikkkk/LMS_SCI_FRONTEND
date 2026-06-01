import 'dart:async';
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
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        timer.cancel();
        await submit(auto: true); // ⏱️ waktu habis → auto submit
        endQuizLock();
      }

      notifyListeners();
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
    _persistAnswers();
    notifyListeners();
  }

  /// Simpan jawaban ke SharedPreferences (fire-and-forget, tidak block UI)
  void _persistAnswers() {
    cacheService?.saveAnswers(_exerciseId, Map.from(_selectedAnswers));
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
    if (_submitted || alreadyDone) return;

    // ⚠️ Validasi hanya berlaku untuk submit manual
    if (!auto && !allAnswered) {
      AppLogger.warning(
        'Submit blocked: Not all questions answered',
        'QuizNotifier',
      );
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harap jawab semua pertanyaan dulu!"),
          ),
        );
      }
      return;
    }

    _quizTimer?.cancel();

    // Snapshot jawaban sebelum submit (aman dari perubahan concurrent)
    final answersSnapshot = Map<String, dynamic>.from(_selectedAnswers);

    try {
      // 🔄 Retry submit hingga 3x dengan backoff
      final submitResult = await _submitWithRetry(
        exerciseId: _exerciseId,
        answers: answersSnapshot,
        auto: auto,
      );

      AppLogger.debug('Submit Result: $submitResult', 'QuizNotifier');

      await Future.delayed(const Duration(milliseconds: 500));

      if (submitResult['is_pending_review'] == true) {
        _isPendingReview = true;
        _finalScore = null;
        AppLogger.info('Pending review mode activated', 'QuizNotifier');
      } else {
        final result = await repository.getResult(exerciseId: _exerciseId);
        AppLogger.debug('Get Result: $result', 'QuizNotifier');
        _finalScore = result?['score'] ?? 0;
        _isPendingReview = false;
        AppLogger.success('Final score: $_finalScore', 'QuizNotifier');
      }

      // ✅ Submit berhasil — hapus cache jawaban
      await cacheService?.clearAnswers(_exerciseId);
      cacheService?.clearQuestionCache(_exerciseId);
      _hasPendingSubmit = false;
    } catch (e) {
      AppLogger.error('Submit failed after retries', e, null, 'QuizNotifier');

      // 💾 Simpan sebagai pending submit — akan bisa dicoba ulang
      await cacheService?.markPendingSubmit(_exerciseId, answersSnapshot, auto);
      _hasPendingSubmit = true;

      // Tetap tandai submitted agar tidak double-submit
      // Score 0 sementara — guru bisa koreksi manual jika perlu
      _finalScore = 0;
      _isPendingReview = false;
    }

    _submitted = true;
    endQuizLock();
    notifyListeners();

    final effectiveTotal = _totalQuizSeconds == noTimeLimit
        ? _defaultQuizSeconds
        : _totalQuizSeconds;
    final duration = effectiveTotal - _remainingSeconds;

    if (auto) {
      logService?.logAutoSubmit(_exerciseId, duration);
    } else {
      logService?.logSubmit(_exerciseId, duration);
    }

    if (auto) {
      NavigationService.instance.navigateToHomeWhenReady();
    }

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
  /// Hanya retry untuk network/timeout error, tidak untuk 4xx.
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
      } catch (e) {
        attempt++;

        // Cek apakah ini error 4xx (client error) — jangan retry
        final is4xx = e.toString().contains('40') ||
            e.toString().contains('DioException') && e.toString().contains('4');

        if (is4xx || attempt >= maxRetries) {
          AppLogger.error(
              'Submit attempt $attempt failed (no more retries): $e',
              'QuizNotifier');
          rethrow;
        }

        AppLogger.warning(
            'Submit attempt $attempt failed, retrying in ${delay.inSeconds}s...',
            'QuizNotifier');
        await Future.delayed(delay);
        delay *= 2; // exponential backoff: 2s → 4s → 8s
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
    _quizTimer?.cancel();
    super.dispose();
  }
}
