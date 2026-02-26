// lib/features/quiz/data/quiz_log_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../auth/domain/auth_notifier.dart';

final quizLogServiceProvider = Provider<QuizLogService>((ref) {
  final dio = ref.read(apiClientProvider);
  return QuizLogService(dio: dio, ref: ref);
});

class QuizLogService {
  final Dio dio;
  final Ref ref;

  QuizLogService({
    required this.dio,
    required this.ref,
  });

  /// Log quiz events (start, submit, lifecycle, etc.)
  Future<void> logEvent({
    required String eventType,
    required String exerciseId,
    required DateTime timestamp,
    int? durationInSeconds,
    bool suspiciousFlag = false,
  }) async {
    // Ambil student secara dinamis setiap kali dipanggil
    final student = ref.read(studentProvider);
    final studentId = student?.id;

    if (studentId == null) {
      AppLogger.warning(
        'Cannot log quiz event: student ID is null',
        'QuizLogService',
      );
      return;
    }

    final payload = {
      'student_id': studentId,
      'exercise_id': exerciseId,
      'event_type': eventType,
      'duration_seconds': durationInSeconds,
      'suspicious_flag': suspiciousFlag ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };

    AppLogger.debug(
      'Attempting to log quiz event: $eventType',
      'QuizLogService',
    );

    try {
      final response = await dio.post(
        'student/quiz/log',
        data: payload,
      );

      AppLogger.debug(
        'Quiz event logged successfully',
        'QuizLogService',
      );

      AppLogger.debug(
        'Response: ${response.data}',
        'QuizLogService',
      );
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to log quiz event: ${e.message}',
        'QuizLogService',
      );

      AppLogger.error(
        'Status code: ${e.response?.statusCode}',
        'QuizLogService',
      );

      AppLogger.error(
        'Response data: ${e.response?.data}',
        'QuizLogService',
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error while logging quiz event: $e',
        'QuizLogService',
      );
    }
  }

  /// Log quiz start
  Future<void> logStart(String exerciseId) async {
    await logEvent(
      eventType: 'START',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
    );
  }

  /// Log quiz submit
  Future<void> logSubmit(String exerciseId, int durationInSeconds) async {
    await logEvent(
      eventType: 'SUBMIT',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      durationInSeconds: durationInSeconds,
    );
  }

  /// Log auto-submit (time expired)
  Future<void> logAutoSubmit(String exerciseId, int durationInSeconds) async {
    await logEvent(
      eventType: 'AUTO_SUBMIT',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      durationInSeconds: durationInSeconds,
    );
  }

  /// Log suspicious activity
  Future<void> logSuspicious(
    String exerciseId,
    String reason,
  ) async {
    await logEvent(
      eventType: 'SUSPICIOUS_$reason',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      suspiciousFlag: true,
    );
  }
}
