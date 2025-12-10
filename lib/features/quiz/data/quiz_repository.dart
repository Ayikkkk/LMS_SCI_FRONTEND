import '../domain/models/question_model.dart';

/// Interface repository quiz.
/// RemoteQuizRepository HARUS mengimplementasikan ini.
abstract class IQuizRepository {
  Future<List<QuestionModel>> fetchQuiz({required String exerciseId});
}

/// Mock repository untuk development / testing offline
class MockQuizRepository implements IQuizRepository {
  @override
  Future<List<QuestionModel>> fetchQuiz({required String exerciseId}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      QuestionModel(
        id: 'q1',
        question: 'Apa kepanjangan dari CPU?',
        options: [
          OptionModel(id: 'a', text: 'Central Process Unit'),
          OptionModel(id: 'b', text: 'Central Processing Unit'),
          OptionModel(id: 'c', text: 'Computer Personal Unit'),
          OptionModel(id: 'd', text: 'Control Processing Unit'),
        ],
        correctOptionId: 'b',
        timeLimitSeconds: 20,
      ),
      QuestionModel(
        id: 'q2',
        question: 'Bahasa pemrograman utama Flutter adalah?',
        options: [
          OptionModel(id: 'a', text: 'Kotlin'),
          OptionModel(id: 'b', text: 'Swift'),
          OptionModel(id: 'c', text: 'Dart'),
          OptionModel(id: 'd', text: 'Java'),
        ],
        correctOptionId: 'c',
        timeLimitSeconds: 15,
      ),
      QuestionModel(
        id: 'q3',
        question: 'State management mana yang populer di Flutter?',
        options: [
          OptionModel(id: 'a', text: 'Redux'),
          OptionModel(id: 'b', text: 'Provider / Riverpod'),
          OptionModel(id: 'c', text: 'Bloc'),
          OptionModel(id: 'd', text: 'Semua benar'),
        ],
        correctOptionId: 'd',
        timeLimitSeconds: 25,
      ),
    ];
  }
}
