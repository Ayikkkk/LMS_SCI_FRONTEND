// lib/features/quiz/domain/models/question_model.dart
class OptionModel {
  final String id;
  final String text;

  OptionModel({required this.id, required this.text});
}

class QuestionModel {
  final String id;
  final String question;
  final List<OptionModel> options;
  final String? correctOptionId;
  final int? timeLimitSeconds;

  QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionId,
    this.timeLimitSeconds,
  });
}
