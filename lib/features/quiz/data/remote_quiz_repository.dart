// lib/features/quiz/data/remote_quiz_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/question_model.dart';
import '../data/quiz_repository.dart'; // IQuizRepository

final remoteQuizRepositoryProvider =
    Provider.autoDispose<RemoteQuizRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return RemoteQuizRepository(dio: dio);
});

class RemoteQuizRepository implements IQuizRepository {
  final Dio dio;

  RemoteQuizRepository({required this.dio});

  String _stripHtmlTags(String input) {
    // Sederhana: hapus tag HTML seperti <p>, <strong>, dsb.
    return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Future<List<QuestionModel>> fetchQuiz({required String exerciseId}) async {
    final response = await dio.get("student/exercises/$exerciseId");

    // Pastikan struktur yang diterima:
    // response.data['data'] memiliki field 'items' -> list soal
    final data = response.data['data'];
    final items = data['items'] ?? [];

    List<QuestionModel> questions = [];

    for (var it in items) {
      // Ambil teks soal (hilangkan tag HTML sederhana jika ada)
      final rawQuestion = it['question']?.toString() ?? '';
      final questionText = _stripHtmlTags(rawQuestion);

      List<OptionModel> options = [];

      // 1) Jika ada kolom 'selection' yang berisi JSON array => parse itu
      if (it['selection'] != null) {
        try {
          final selRaw = it['selection'];
          final parsedSelections = (selRaw is String) ? jsonDecode(selRaw) : selRaw;

          if (parsedSelections is List) {
            for (int i = 0; i < parsedSelections.length; i++) {
              final rawOpt = parsedSelections[i]?.toString() ?? '';
              final optText = _stripHtmlTags(rawOpt);

              // id option -> a, b, c, d ...
              final id = String.fromCharCode(97 + i); // 0->a, 1->b, ...
              options.add(OptionModel(id: id, text: optText));
            }
          }
        } catch (e) {
          // jika parse gagal, ignore dan coba fallback ke option_a...
          // debug print optional
        }
      }

      // 2) Fallback: jika tidak ada selection, coba ambil option_a..option_d
      if (options.isEmpty) {
        final rawOptions = [
          it['option_a'],
          it['option_b'],
          it['option_c'],
          it['option_d']
        ];

        for (var i = 0; i < rawOptions.length; i++) {
          final r = rawOptions[i];
          if (r != null) {
            final text = _stripHtmlTags(r.toString());
            final id = String.fromCharCode(97 + i);
            options.add(OptionModel(id: id, text: text));
          }
        }
      }

      // 3) Ambil kunci jawaban dari kolom 'answer'
      String? correctId;
      if (it['answer'] != null) {
        try {
          final ansRaw = it['answer'];
          final parsedAnswer = (ansRaw is String) ? jsonDecode(ansRaw) : ansRaw;

          if (parsedAnswer is List && parsedAnswer.isNotEmpty) {
            // sering disimpan seperti ["a"]
            correctId = parsedAnswer[0]?.toString();
          } else if (parsedAnswer is String) {
            correctId = parsedAnswer;
          } else if (parsedAnswer != null) {
            correctId = parsedAnswer.toString();
          }
        } catch (e) {
          // fallback: jika answer simple string seperti "a"
          correctId = it['answer']?.toString();
        }
      } else {
        // juga coba field 'answer' plain
        correctId = it['answer']?.toString();
      }

      // 4) time limit (jika ada)
      int? timeLimit;
      if (it['time_limit'] != null) {
        timeLimit = int.tryParse(it['time_limit'].toString());
      }

      // Tambah question model
      questions.add(QuestionModel(
        id: it['id'].toString(),
        question: questionText,
        options: options,
        correctOptionId: correctId,
        timeLimitSeconds: timeLimit,
      ));
    }

    return questions;
  }
}
