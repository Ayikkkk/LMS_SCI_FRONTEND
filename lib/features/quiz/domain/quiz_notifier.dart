// lib/features/quiz/domain/quiz_notifier.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/quiz_repository.dart';
import 'models/question_model.dart';

class QuizNotifier extends ChangeNotifier {
  final IQuizRepository repository;

  QuizNotifier({required this.repository});

  /// TOTAL WAKTU QUIZ (30 menit)
  static const int totalQuizSeconds = 30 * 60;

  late String _exerciseId;

  // ================= STATE =================
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

  /// nilai FINAL dari backend
  int? _finalScore;
  int? get finalScore => _finalScore;

  bool get alreadyDone => _finalScore != null;

  bool _submitted = false;
  bool get submitted => _submitted;

  Timer? _quizTimer;
  int _remainingSeconds = totalQuizSeconds;
  int get remainingSeconds => _remainingSeconds;

  // ================= LOAD =================
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
      // 🔒 CEK: SUDAH PERNAH MENGERJAKAN?
      final existingScore = await repository.getResultScore(
        exerciseId: exerciseId,
      );

      if (existingScore != null) {
        // sudah pernah → langsung tampilkan hasil
        _finalScore = existingScore;
        _submitted = true;
        _loading = false;
        notifyListeners();
        return;
      }

      // belum → load soal
      _questions = await repository.fetchQuiz(
        exerciseId: exerciseId,
      );

      _remainingSeconds = totalQuizSeconds;

      if (_questions.isNotEmpty) {
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

    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;

      if (_remainingSeconds <= 0) {
        timer.cancel();
        submit();
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

  // ================= NAV =================
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
  Future<void> submit() async {
    if (_submitted || alreadyDone) return;

    _quizTimer?.cancel();

    try {
      // 1️⃣ submit jawaban
      await repository.submitQuiz(
        exerciseId: _exerciseId,
        answers: _selectedAnswers,
      );

      // 2️⃣ AMBIL NILAI FINAL DARI BACKEND
      final score = await repository.getResultScore(
        exerciseId: _exerciseId,
      );

      // 3️⃣ PASTIKAN finalScore TERISI
      _finalScore = score ?? 0;
    } catch (e) {
      debugPrint('Submit error: $e');
      // fallback agar UI tidak loading terus
      _finalScore = 0;
    }

    // 4️⃣ BARU tandai submitted
    _submitted = true;
    notifyListeners();
  }

  // ================= RESET (DEV ONLY) =================
  void reset() {
    _quizTimer?.cancel();
    _currentIndex = 0;
    _submitted = false;
    _finalScore = null;
    _selectedAnswers.clear();
    _remainingSeconds = totalQuizSeconds;
    _startGlobalTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    super.dispose();
  }
}
