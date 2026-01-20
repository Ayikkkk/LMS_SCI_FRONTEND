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

  final Map<String, String> _selectedAnswers = {};
  Map<String, String> get selectedAnswers => _selectedAnswers;

  int? _finalScore;
  int? get finalScore => _finalScore;

  bool get alreadyDone => _finalScore != null;

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
    _currentIndex = 0;
    _selectedAnswers.clear();
    _questions.clear();
    _quizTimer?.cancel();

    notifyListeners();

    try {
      // 🔍 Cek apakah sudah pernah dikerjakan
      final existingScore = await repository.getResultScore(
        exerciseId: exerciseId,
      );

      if (existingScore != null) {
        _finalScore = existingScore;
        _submitted = true;
        _loading = false;
        endQuizLock();
        notifyListeners();
        return;
      }

      // 🧩 Load soal dari backend
      _questions = await repository.fetchQuiz(exerciseId: exerciseId);
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
  void selectOption(String questionId, String optionId) {
    if (_submitted || alreadyDone) return;
    _selectedAnswers[questionId] = optionId;
    notifyListeners();
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
      await repository.submitQuiz(
        exerciseId: _exerciseId,
        answers: _selectedAnswers,
        auto: auto,
      );

      // 🧩 Tunggu sebentar agar backend sempat menyimpan skor
      await Future.delayed(const Duration(milliseconds: 500));

      // 🧩 Ambil nilai final dari backend (sumber kebenaran)
      final backendScore =
          await repository.getResultScore(exerciseId: _exerciseId);

      // ✅ Gunakan skor dari backend langsung (tanpa hitung ulang)
      _finalScore = backendScore ?? 0;

      debugPrint('✅ Final score (from backend): $_finalScore');
    } catch (e) {
      debugPrint('Submit error: $e');
      _finalScore = 0;
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
