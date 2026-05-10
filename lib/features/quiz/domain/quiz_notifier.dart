import 'dart:async';
import 'package:flutter/material.dart';
import '../../../navigation_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/analytics_service.dart';
import '../data/quiz_repository.dart';
import '../data/quiz_log_service.dart';
import 'models/question_model.dart';

class QuizNotifier extends ChangeNotifier {
  final IQuizRepository repository;
  final QuizLogService? logService;

  QuizNotifier({required this.repository, this.logService});

  static const int totalQuizSeconds = 2 * 60;

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
  int _remainingSeconds = totalQuizSeconds;
  int get remainingSeconds => _remainingSeconds;

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

        // Cek apakah pending review (untuk tipe AKM)
        if (result['is_pending_review'] == true) {
          _isPendingReview = true;
          _submitted = true;
          _loading = false;
          endQuizLock();
          notifyListeners();
          return;
        }

        // Jika sudah ada score
        if (result['score'] != null) {
          _finalScore = result['score'];
          _submitted = true;
          _loading = false;
          endQuizLock();
          notifyListeners();
          return;
        }
      }

      // 🧩 Load soal dari backend
      final quizData = await repository.fetchQuiz(exerciseId: exerciseId);
      _questions = quizData['questions'];
      _exerciseTypeName = quizData['exercise_type_name'];
      _remainingSeconds = totalQuizSeconds;

      if (_questions.isNotEmpty) {
        startQuizLock(exerciseId);
        _startGlobalTimer();

        // Log START event
        logService?.logStart(exerciseId);

        // Track quiz start in Analytics
        await AnalyticsService.logQuizStart(
          quizId: exerciseId,
          quizName: _exerciseTypeName ?? 'Unknown',
          quizType: _exerciseTypeName ?? 'Unknown',
        );
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  // ================= TIMER =================
  void _startGlobalTimer() {
    _quizTimer?.cancel();

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
    notifyListeners();
  }

  /// Set text answer (for essay, short answer, fill in the blank)
  void setTextAnswer(String questionId, String text) {
    if (_submitted || alreadyDone) return;
    _selectedAnswers[questionId] = text;
    notifyListeners();
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

    try {
      // 🧩 Kirim jawaban ke backend
      final submitResult = await repository.submitQuiz(
        exerciseId: _exerciseId,
        answers: _selectedAnswers,
        auto: auto,
      );

      AppLogger.debug('Submit Result: $submitResult', 'QuizNotifier');
      AppLogger.debug(
        'is_pending_review: ${submitResult['is_pending_review']}',
        'QuizNotifier',
      );
      AppLogger.debug('score: ${submitResult['score']}', 'QuizNotifier');

      // 🧩 Tunggu sebentar agar backend sempat menyimpan
      await Future.delayed(const Duration(milliseconds: 500));

      // Cek apakah perlu review manual (untuk tipe AKM)
      if (submitResult['is_pending_review'] == true) {
        _isPendingReview = true;
        _finalScore = null;
        AppLogger.info('Pending review mode activated', 'QuizNotifier');
      } else {
        // 🧩 Ambil nilai final dari backend (sumber kebenaran)
        final result = await repository.getResult(exerciseId: _exerciseId);
        AppLogger.debug('Get Result: $result', 'QuizNotifier');

        _finalScore = result?['score'] ?? 0;
        _isPendingReview = false;
        AppLogger.success('Final score: $_finalScore', 'QuizNotifier');
      }
    } catch (e) {
      AppLogger.error('Submit error', e, null, 'QuizNotifier');
      _finalScore = 0;
      _isPendingReview = false;
    }

    _submitted = true;
    endQuizLock(); // unlock dulu sebelum notify agar PopScope langsung update
    notifyListeners();

    // Hitung durasi pengerjaan
    final duration = totalQuizSeconds - _remainingSeconds;

    // Log SUBMIT / AUTO_SUBMIT event dengan durasi
    if (auto) {
      logService?.logAutoSubmit(_exerciseId, duration);
    } else {
      logService?.logSubmit(_exerciseId, duration);
    }

    // Jika auto-submit (waktu habis saat app di background),
    // navigasi ke home — pakai navigateToHomeWhenReady agar
    // bisa dieksekusi saat app kembali ke foreground
    if (auto) {
      NavigationService.instance.navigateToHomeWhenReady();
    }

    // Track quiz completion in Analytics
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

  // ================= RESET =================
  void reset() {
    _quizTimer?.cancel();
    _currentIndex = 0;
    _submitted = false;
    _finalScore = null;
    _selectedAnswers.clear();
    _remainingSeconds = totalQuizSeconds;

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
