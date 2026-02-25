// lib/features/quiz/domain/models/question_model.dart

/// Question types supported by the quiz system
enum QuestionType {
  multipleChoice, // Single choice (radio buttons)
  multipleAnswer, // Multiple choice (checkboxes)
  trueFalse, // True/False statement
  yesNo, // Yes/No question
  shortAnswer, // Text field for short answers
  essay, // Text area for essay/description
  fillInTheBlank, // Text field for fill in the blank
}

class OptionModel {
  final String id;
  final String text;

  OptionModel({required this.id, required this.text});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
    };
  }
}

class QuestionModel {
  final String id;
  final String question;
  final QuestionType type;
  final List<OptionModel> options;
  final String? correctOptionId;
  final int? timeLimitSeconds;
  final int? maxLength; // For text answers
  final bool? isRequired;

  QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    this.correctOptionId,
    this.timeLimitSeconds,
    this.maxLength,
    this.isRequired = true,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Determine question type from backend data
    QuestionType type = _parseQuestionType(json);

    return QuestionModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      type: type,
      options: _parseOptions(json, type),
      correctOptionId: json['correct_option_id']?.toString(),
      timeLimitSeconds: json['time_limit_seconds'] as int?,
      maxLength: json['max_length'] as int?,
      isRequired: json['is_required'] as bool? ?? true,
    );
  }

  static QuestionType _parseQuestionType(Map<String, dynamic> json) {
    final typeStr = json['type']?.toString().toLowerCase() ?? '';
    final questionText = json['question']?.toString().toLowerCase() ?? '';

    // Check explicit type field first
    switch (typeStr) {
      case 'multiple_choice':
      case 'single_choice':
      case 'radio':
        return QuestionType.multipleChoice;
      case 'multiple_answer':
      case 'multiple_select':
      case 'checkbox':
      case 'checkboxes':
      case 'multi':
        return QuestionType.multipleAnswer;
      case 'true_false':
      case 'statement':
      case 'truefalse':
        return QuestionType.trueFalse;
      case 'yes_no':
      case 'yesno':
        return QuestionType.yesNo;
      case 'short_answer':
      case 'fill_blank':
      case 'fill_in_the_blank':
      case 'text':
      case 'input':
        return QuestionType.fillInTheBlank;
      case 'essay':
      case 'description':
      case 'long_answer':
      case 'textarea':
        return QuestionType.essay;
    }

    // Check for multiple answer indicators
    // Priority: Check flags first
    if (json['multiple_correct'] == true ||
        json['allow_multiple'] == true ||
        json['is_multiple'] == true ||
        json['multi_select'] == true) {
      return QuestionType.multipleAnswer;
    }

    // Check question text for multiple answer keywords
    if (questionText.contains('pilih semua') ||
        questionText.contains('select all') ||
        questionText.contains('pilih lebih dari satu') ||
        questionText.contains('more than one') ||
        questionText.contains('yang benar') && questionText.contains('semua')) {
      return QuestionType.multipleAnswer;
    }

    // Fallback: detect from question text patterns
    if (questionText.contains('benar') && questionText.contains('salah')) {
      return QuestionType.trueFalse;
    }
    if (questionText.contains('ya') && questionText.contains('tidak')) {
      return QuestionType.yesNo;
    }

    // Check if it's a text-based question (no options or empty options)
    final options = json['options'] ?? json['selection'];
    if (options == null || (options is List && options.isEmpty)) {
      // Determine if short answer or essay based on max_length
      final maxLength = json['max_length'] as int?;
      if (maxLength != null && maxLength <= 200) {
        return QuestionType.shortAnswer;
      }
      return QuestionType.essay;
    }

    // Default to multiple choice
    return QuestionType.multipleChoice;
  }

  static List<OptionModel> _parseOptions(
      Map<String, dynamic> json, QuestionType type) {
    // For text-based questions, no options needed
    if (type == QuestionType.shortAnswer ||
        type == QuestionType.essay ||
        type == QuestionType.fillInTheBlank) {
      return [];
    }

    // For True/False
    if (type == QuestionType.trueFalse) {
      return [
        OptionModel(id: 'true', text: 'Benar'),
        OptionModel(id: 'false', text: 'Salah'),
      ];
    }

    // For Yes/No
    if (type == QuestionType.yesNo) {
      return [
        OptionModel(id: 'yes', text: 'Ya'),
        OptionModel(id: 'no', text: 'Tidak'),
      ];
    }

    // Parse options from JSON
    List<OptionModel> options = [];

    // Backend sends 'options' field as array directly
    if (json['options'] != null && json['options'] is List) {
      final optionsList = json['options'] as List;

      // Debug
      print(
          'DEBUG QuestionModel: Parsing ${optionsList.length} options for question ${json['id']}');

      for (int i = 0; i < optionsList.length; i++) {
        final opt = optionsList[i];
        if (opt is Map) {
          options.add(OptionModel.fromJson(opt as Map<String, dynamic>));
        } else {
          // Backend sends simple string array, create option with letter id
          final optionModel = OptionModel(
            id: String.fromCharCode(97 + i), // a, b, c, d, e
            text: opt.toString(),
          );
          options.add(optionModel);
          print(
              'DEBUG QuestionModel: Created option ${optionModel.id}: ${optionModel.text}');
        }
      }

      print('DEBUG QuestionModel: Total ${options.length} options created');
      return options;
    } else {
      print(
          'DEBUG QuestionModel: No options array found. json[options] = ${json['options']}');
    }

    return options;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.toString().split('.').last,
      'options': options.map((o) => o.toJson()).toList(),
      'correct_option_id': correctOptionId,
      'time_limit_seconds': timeLimitSeconds,
      'max_length': maxLength,
      'is_required': isRequired,
    };
  }
}
