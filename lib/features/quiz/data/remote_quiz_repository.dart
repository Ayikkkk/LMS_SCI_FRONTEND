// lib/features/quiz/data/remote_quiz_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
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
  Future<List<QuestionModel>> fetchQuiz({
    required String exerciseId,
  }) async {
    final response = await dio.get(
      'student/exercises/$exerciseId',
    );

    final data = response.data['data'];
    final items = data['items'] ?? [];

    final List<QuestionModel> questions = [];

    for (final it in items) {
      final questionText = _stripHtmlTags(it['question']?.toString() ?? '');

      List<OptionModel> options = [];

      // selection JSON
      if (it['selection'] != null) {
        try {
          final raw = it['selection'];
          final parsed = raw is String ? jsonDecode(raw) : raw;

          if (parsed is List) {
            for (int i = 0; i < parsed.length; i++) {
              options.add(
                OptionModel(
                  id: String.fromCharCode(97 + i), // a,b,c,d
                  text: _stripHtmlTags(parsed[i].toString()),
                ),
              );
            }
          }
        } catch (_) {}
      }

      // fallback option_a..d
      if (options.isEmpty) {
        final rawOptions = [
          it['option_a'],
          it['option_b'],
          it['option_c'],
          it['option_d'],
        ];

        for (int i = 0; i < rawOptions.length; i++) {
          if (rawOptions[i] != null) {
            options.add(
              OptionModel(
                id: String.fromCharCode(97 + i),
                text: _stripHtmlTags(rawOptions[i].toString()),
              ),
            );
          }
        }
      }

      questions.add(
        QuestionModel(
          id: it['id'].toString(),
          question: questionText,
          options: options,
          correctOptionId: null, // backend yang menilai
        ),
      );
    }

    return questions;
  }

  // ================= SUBMIT QUIZ =================
  @override
  Future<void> submitQuiz({
    required String exerciseId,
    required Map<String, String> answers,
  }) async {
    await dio.post(
      'student/exercises/$exerciseId/submit',
      data: {
        'answers': answers,
      },
    );
  }

  // ================= GET RESULT =================
  @override
  Future<int?> getResultScore({
    required String exerciseId,
  }) async {
    try {
      final res = await dio.get(
        'student/exercises/$exerciseId/result',
      );

      final data = res.data['data'];
      if (data == null) return null;

      final rawScore = data['exercise_point'];

      // 🔑 HANDLE SEMUA KEMUNGKINAN TIPE
      if (rawScore is int) return rawScore;
      if (rawScore is double) return rawScore.toInt();
      if (rawScore is String) return int.tryParse(rawScore);

      return null;
    } catch (e) {
      return null;
    }
  }
}
