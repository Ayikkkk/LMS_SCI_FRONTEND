import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:lms_frontend/features/quiz/data/quiz_repository.dart';
import 'package:lms_frontend/features/quiz/domain/quiz_notifier.dart';
import 'package:lms_frontend/features/quiz/domain/models/question_model.dart';

import 'quiz_notifier_test.mocks.dart';

@GenerateMocks([IQuizRepository])
void main() {
  late MockIQuizRepository mockRepo;
  late QuizNotifier notifier;

  QuestionModel _makeQuestion(String id) => QuestionModel(
        id: id,
        question: 'Question $id?',
        type: QuestionType.multipleChoice,
        options: [
          OptionModel(id: 'a', text: 'Option A'),
          OptionModel(id: 'b', text: 'Option B'),
        ],
      );

  setUp(() {
    mockRepo = MockIQuizRepository();
    notifier = QuizNotifier(repository: mockRepo);
  });

  tearDown(() => notifier.dispose());

  group('QuizNotifier — initial state', () {
    test('starts with loading=false, submitted=false, empty questions', () {
      expect(notifier.loading, false);
      expect(notifier.submitted, false);
      expect(notifier.questions, isEmpty);
      expect(notifier.error, isNull);
    });
  });

  group('QuizNotifier — loadQuiz', () {
    test('loads questions successfully', () async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => null);
      when(mockRepo.fetchQuiz(exerciseId: '1')).thenAnswer((_) async => {
            'questions': [_makeQuestion('q1'), _makeQuestion('q2')],
            'exercise_type_name': 'Ulangan Harian',
          });

      await notifier.loadQuiz(exerciseId: '1');

      expect(notifier.loading, false);
      expect(notifier.questions.length, 2);
      expect(notifier.exerciseTypeName, 'Ulangan Harian');
      expect(notifier.submitted, false);
    });

    test('sets submitted=true if result already exists', () async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => {
            'score': 80,
            'is_pending_review': false,
            'exercise_type_name': 'UH',
          });

      await notifier.loadQuiz(exerciseId: '1');

      expect(notifier.submitted, true);
      expect(notifier.finalScore, 80);
    });

    test('sets isPendingReview=true for AKM type', () async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => {
            'is_pending_review': true,
            'exercise_type_name': 'AKM',
          });

      await notifier.loadQuiz(exerciseId: '1');

      expect(notifier.submitted, true);
      expect(notifier.isPendingReview, true);
    });

    test('sets error on exception', () async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => null);
      when(mockRepo.fetchQuiz(exerciseId: '1'))
          .thenThrow(Exception('Network error'));

      await notifier.loadQuiz(exerciseId: '1');

      expect(notifier.error, isNotNull);
      expect(notifier.loading, false);
    });
  });

  group('QuizNotifier — answers', () {
    setUp(() async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => null);
      when(mockRepo.fetchQuiz(exerciseId: '1')).thenAnswer((_) async => {
            'questions': [_makeQuestion('q1'), _makeQuestion('q2')],
            'exercise_type_name': 'UH',
          });
      await notifier.loadQuiz(exerciseId: '1');
    });

    test('selectOption stores answer', () {
      notifier.selectOption('q1', 'a');
      expect(notifier.selectedAnswers['q1'], 'a');
    });

    test('allAnswered is false when not all answered', () {
      notifier.selectOption('q1', 'a');
      expect(notifier.allAnswered, false);
    });

    test('allAnswered is true when all answered', () {
      notifier.selectOption('q1', 'a');
      notifier.selectOption('q2', 'b');
      expect(notifier.allAnswered, true);
    });

    test('toggleMultipleOption adds and removes', () {
      notifier.toggleMultipleOption('q1', 'a');
      expect((notifier.selectedAnswers['q1'] as List).contains('a'), true);

      notifier.toggleMultipleOption('q1', 'a');
      expect((notifier.selectedAnswers['q1'] as List).contains('a'), false);
    });

    test('setTextAnswer stores text', () {
      notifier.setTextAnswer('q1', 'my answer');
      expect(notifier.getTextAnswer('q1'), 'my answer');
    });
  });

  group('QuizNotifier — navigation', () {
    setUp(() async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => null);
      when(mockRepo.fetchQuiz(exerciseId: '1')).thenAnswer((_) async => {
            'questions': [
              _makeQuestion('q1'),
              _makeQuestion('q2'),
              _makeQuestion('q3'),
            ],
            'exercise_type_name': 'UH',
          });
      await notifier.loadQuiz(exerciseId: '1');
    });

    test('next increments currentIndex', () {
      notifier.selectOption('q1', 'a');
      notifier.next();
      expect(notifier.currentIndex, 1);
    });

    test('previous decrements currentIndex', () {
      notifier.selectOption('q1', 'a');
      notifier.next();
      notifier.previous();
      expect(notifier.currentIndex, 0);
    });

    test('previous does nothing at index 0', () {
      notifier.previous();
      expect(notifier.currentIndex, 0);
    });
  });

  group('QuizNotifier — submit', () {
    setUp(() async {
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => null);
      when(mockRepo.fetchQuiz(exerciseId: '1')).thenAnswer((_) async => {
            'questions': [_makeQuestion('q1')],
            'exercise_type_name': 'UH',
          });
      await notifier.loadQuiz(exerciseId: '1');
    });

    test('submit sets submitted=true and finalScore', () async {
      notifier.selectOption('q1', 'a');

      when(mockRepo.submitQuiz(
        exerciseId: '1',
        answers: {'q1': 'a'},
        auto: false,
      )).thenAnswer((_) async => {
            'is_pending_review': false,
            'score': 100,
          });
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => {
            'score': 100,
            'is_pending_review': false,
            'exercise_type_name': 'UH',
          });

      await notifier.submit();

      expect(notifier.submitted, true);
      expect(notifier.finalScore, 100);
    });

    test('submit does nothing if already submitted', () async {
      notifier.selectOption('q1', 'a');

      when(mockRepo.submitQuiz(
              exerciseId: anyNamed('exerciseId'),
              answers: anyNamed('answers'),
              auto: anyNamed('auto')))
          .thenAnswer((_) async => {'is_pending_review': false, 'score': 50});
      when(mockRepo.getResult(exerciseId: '1')).thenAnswer((_) async => {
            'score': 50,
            'is_pending_review': false,
            'exercise_type_name': 'UH'
          });

      await notifier.submit();
      await notifier.submit(); // second call should be no-op

      verify(mockRepo.submitQuiz(
        exerciseId: anyNamed('exerciseId'),
        answers: anyNamed('answers'),
        auto: anyNamed('auto'),
      )).called(1);
    });
  });
}
