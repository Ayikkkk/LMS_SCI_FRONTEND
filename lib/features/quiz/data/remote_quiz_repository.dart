// lib/features/quiz/data/remote_quiz_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../domain/models/question_model.dart';
import 'quiz_repository.dart';

final remoteQuizRepositoryProvider =
    Provider.autoDispose<RemoteQuizRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return RemoteQuizRepository(dio: dio);
});

class RemoteQuizRepository implements IQuizRepository {
  final Dio dio;

  RemoteQuizRepository({required this.dio});

  String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  // ================= FETCH QUIZ =================
  @override
  Future<Map<String, dynamic>> fetchQuiz({
    required String exerciseId,
  }) async {
    final response = await dio.get(
      'student/exercises/$exerciseId',
    );

    final data = response.data['data'];
    final items = data['items'] ?? [];
    final exerciseTypeName = data['exercise_type_name'] ?? data['type_name'];

    final List<QuestionModel> questions = [];

    for (final it in items) {
      final questionText = _stripHtmlTags(it['question']?.toString() ?? '');

      // Debug: Print raw item data
      AppLogger.debug(
          'Raw item: id=${it['id']}, type=${it['type']}, model_id=${it['exercise_model_id']}, options=${it['options']}, exercise_choice=${it['exercise_choice']}, is_multiple=${it['is_multiple']}',
          'RemoteQuizRepository');

      // Parse options with fallback for different formats
      List<dynamic> options = [];

      // Try 'options' field first (new format)
      if (it['options'] != null && it['options'] is List) {
        options = (it['options'] as List)
            .map((opt) => _stripHtmlTags(opt.toString()))
            .toList();
        AppLogger.debug('Parsed options from options field: $options',
            'RemoteQuizRepository');
      }
      // Fallback: try 'exercise_choice' field (might be JSON string or comma-separated)
      else if (it['exercise_choice'] != null) {
        final exerciseChoice = it['exercise_choice'];

        if (exerciseChoice is List) {
          // Already an array
          options = exerciseChoice
              .map((opt) => _stripHtmlTags(opt.toString()))
              .toList();
          AppLogger.debug(
              'Parsed options from exercise_choice (array): $options',
              'RemoteQuizRepository');
        } else if (exerciseChoice is String && exerciseChoice.isNotEmpty) {
          // Try to parse as JSON first
          try {
            final decoded = jsonDecode(exerciseChoice);
            if (decoded is List) {
              options =
                  decoded.map((opt) => _stripHtmlTags(opt.toString())).toList();
              AppLogger.debug(
                  'Parsed options from exercise_choice (JSON): $options',
                  'RemoteQuizRepository');
            }
          } catch (e) {
            // Not JSON, try comma-separated
            options = exerciseChoice
                .split(',')
                .map((opt) => _stripHtmlTags(opt.trim()))
                .where((opt) => opt.isNotEmpty)
                .toList();
            AppLogger.debug(
                'Parsed options from exercise_choice (CSV): $options',
                'RemoteQuizRepository');
          }
        }
      }

      if (options.isEmpty) {
        AppLogger.warning(
            'No options found for question ${it['id']}. This might be a text-based question.',
            'RemoteQuizRepository');
      }

      // Create question model with backend data
      final question = QuestionModel.fromJson({
        'id': it['id'].toString(),
        'question': questionText,
        'type': it['type']?.toString(), // Backend already maps this
        'options': options, // Use options array from backend
        'multiple_correct': it['multiple_correct'] ?? false,
        'allow_multiple': it['allow_multiple'] ?? false,
        'is_multiple': it['is_multiple'] ?? false,
        'exercise_model_id': it['exercise_model_id'],
        'max_length': it['max_length'],
        'is_required': it['is_required'],
      });

      // Debug: Print question info
      AppLogger.debug(
          'Created Question ${question.id}: type=${question.type}, options_count=${question.options.length}',
          'RemoteQuizRepository');

      questions.add(question);
    }

    return {
      'questions': questions,
      'exercise_type_name': exerciseTypeName,
    };
  }

  // ================= SUBMIT QUIZ =================
  @override
  Future<Map<String, dynamic>> submitQuiz({
    required String exerciseId,
    required Map<String, dynamic> answers,
    bool auto = false,
  }) async {
    // Convert answers to proper format for backend
    final Map<String, dynamic> formattedAnswers = {};

    answers.forEach((questionId, answer) {
      if (answer is List) {
        // Multiple answer: join with comma or send as array
        formattedAnswers[questionId] = answer.join(',');
      } else {
        // Single answer or text
        formattedAnswers[questionId] = answer.toString();
      }
    });

    AppLogger.debug('Submitting quiz: $exerciseId', 'RemoteQuizRepository');

    final response = await dio.post(
      'student/exercises/$exerciseId/submit',
      data: {
        'answers': formattedAnswers,
        'auto_submit': auto,
      },
    );

    AppLogger.debug(
        'Submit response: ${response.data}', 'RemoteQuizRepository');

    // Backend mengirim is_pending_review di root response, bukan di data
    final isPendingReview = response.data['is_pending_review'] ?? false;
    final score = response.data['score'];
    final data = response.data['data'] ?? {};

    AppLogger.debug(
        'Parsed - is_pending_review: $isPendingReview, score: $score',
        'RemoteQuizRepository');

    return {
      'is_pending_review': isPendingReview,
      'score': score,
      'message': response.data['message'],
      'data': data,
    };
  }

  // ================= GET RESULT =================
  @override
  Future<Map<String, dynamic>?> getResult({
    required String exerciseId,
  }) async {
    try {
      final res = await dio.get(
        'student/exercises/$exerciseId/result',
      );

      final data = res.data['data'];
      if (data == null) return null;

      final rawScore = data['exercise_point'];
      final isPendingReview = data['is_pending_review'] ?? false;
      final exerciseTypeName = data['exercise_type_name'] ?? data['type_name'];

      // Parse score
      int? score;
      if (rawScore is int) {
        score = rawScore;
      } else if (rawScore is double) {
        score = rawScore.toInt();
      } else if (rawScore is String) {
        score = int.tryParse(rawScore);
      }

      return {
        'score': score,
        'is_pending_review': isPendingReview,
        'exercise_type_name': exerciseTypeName,
      };
    } catch (e) {
      return null;
    }
  }

  // Legacy method for backward compatibility
  @override
  Future<int?> getResultScore({
    required String exerciseId,
  }) async {
    final result = await getResult(exerciseId: exerciseId);
    return result?['score'];
  }
}
