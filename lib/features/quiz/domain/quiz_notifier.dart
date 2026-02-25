import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../navigation_service.dart';
import '../data/quiz_repository.dart';
import 'models/question_model.dart';

class QuizNotifier extends ChangeNotifier {
  final IQuizRepository repository;

  QuizNotifier({required this.repository});

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
    } else {
      submit();
    }
    notifyListeners();
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
      debugPrint("Harap jawab semua pertanyaan sebelum menyelesaikan kuis!");
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

      // 🧩 DEBUG: Print response dari backend
      debugPrint('📦 Submit Result: $submitResult');
      debugPrint('📦 is_pending_review: ${submitResult['is_pending_review']}');
      debugPrint('📦 score: ${submitResult['score']}');

      // 🧩 Tunggu sebentar agar backend sempat menyimpan
      await Future.delayed(const Duration(milliseconds: 500));

      // Cek apakah perlu review manual (untuk tipe AKM)
      if (submitResult['is_pending_review'] == true) {
        _isPendingReview = true;
        _finalScore = null;
        debugPrint('✅ Pending review mode activated');
      } else {
        // 🧩 Ambil nilai final dari backend (sumber kebenaran)
        final result = await repository.getResult(exerciseId: _exerciseId);
        debugPrint('📦 Get Result: $result');

        _finalScore = result?['score'] ?? 0;
        _isPendingReview = false;
        debugPrint('✅ Final score: $_finalScore');
      }
    } catch (e) {
      debugPrint('❌ Submit error: $e');
      _finalScore = 0;
      _isPendingReview = false;
    }

    _submitted = true;
    notifyListeners();
    endQuizLock();
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
