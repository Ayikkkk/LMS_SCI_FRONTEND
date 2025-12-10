// lib/features/quiz/domain/quiz_notifier.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/quiz_repository.dart' show IQuizRepository;
import '../domain/models/question_model.dart';

class QuizNotifier extends ChangeNotifier {
  final IQuizRepository repository;

  QuizNotifier({required this.repository});

  List<QuestionModel> _questions = [];
  List<QuestionModel> get questions => _questions;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Map<String, String> _selectedAnswers = {};
  Map<String, String> get selectedAnswers => _selectedAnswers;

  int _score = 0;
  int get score => _score;

  bool _submitted = false;
  bool get submitted => _submitted;

  Timer? _questionTimer;
  int _remainingSeconds = 0;
  int get remainingSeconds => _remainingSeconds;

  /// Memuat soal dari repository.
  /// Parameter exerciseId wajib (sesuai API backend kamu).
  Future<void> loadQuiz({required String exerciseId}) async {
    _loading = true;
    _error = null;
    _questions = [];
    _selectedAnswers = {};
    _score = 0;
    _submitted = false;
    _currentIndex = 0;
    _remainingSeconds = 0;
    notifyListeners();

    try {
      final fetched = await repository.fetchQuiz(exerciseId: exerciseId);
      _questions = fetched;
      // jika ada soal, mulai timer untuk soal pertama
      if (_questions.isNotEmpty) {
        _startTimerForCurrentQuestion();
      }
    } catch (e, st) {
      _error = e.toString();
      // optional: debug print
      if (kDebugMode) {
        print('QuizNotifier.loadQuiz error: $e\n$st');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _startTimerForCurrentQuestion() {
    _questionTimer?.cancel();

    if (_questions.isEmpty || _currentIndex < 0 || _currentIndex >= _questions.length) {
      _remainingSeconds = 0;
      notifyListeners();
      return;
    }

    final q = _questions[_currentIndex];
    _remainingSeconds = q.timeLimitSeconds ?? 0;

    if (_remainingSeconds > 0) {
      _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          // otomatis lompat ke soal selanjutnya; flag auto true supaya bisa dibedakan apabila perlu
          next(auto: true);
        }
        notifyListeners();
      });
    } else {
      // tidak ada limit waktu
      _remainingSeconds = 0;
      notifyListeners();
    }
  }

  void selectOption(String questionId, String optionId) {
    if (_submitted) return;
    _selectedAnswers[questionId] = optionId;
    notifyListeners();
  }

  void next({bool auto = false}) {
    // jika masih ada soal setelah ini, pindah ke soal berikutnya
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _startTimerForCurrentQuestion();
      notifyListeners();
    } else {
      // jika tidak ada soal lagi, kumpulkan/submit lokal
      submit();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _startTimerForCurrentQuestion();
      notifyListeners();
    }
  }

  /// Submit lokal: hitung skor berdasarkan pilihan user dan kunci jawaban.
  /// (Jika ingin mengirim ke server, buat method submitRemote/submitToServer)
  void submit() {
    _questionTimer?.cancel();
    _score = 0;
    for (var q in _questions) {
      final selected = _selectedAnswers[q.id];
      if (selected != null && selected == q.correctOptionId) {
        _score++;
      }
    }
    _submitted = true;
    notifyListeners();
  }

  /// Reset quiz (tetap dengan soal yang sama)
  void reset() {
    _questionTimer?.cancel();
    _selectedAnswers.clear();
    _score = 0;
    _submitted = false;
    _currentIndex = 0;
    if (_questions.isNotEmpty) {
      _startTimerForCurrentQuestion();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }
}
