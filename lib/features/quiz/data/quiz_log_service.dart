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

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Track exercise IDs yang sudah di-log SUBMIT/AUTO_SUBMIT
  // agar tidak terjadi double log
  final Set<String> _submittedExercises = {};

  QuizLogService({required this.dio, required this.ref});

  /// Log quiz events (start, submit, lifecycle, etc.)
  Future<void> logEvent({
    required String eventType,
    required String exerciseId,
    required DateTime timestamp,
    int? durationInSeconds,
    bool suspiciousFlag = false,
  }) async {
    final student = ref.read(studentProvider);
    final studentId = student?.id;

    if (studentId == null) {
      AppLogger.warning(
          'Cannot log quiz event: student ID is null', 'QuizLogService');
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
        'Attempting to log quiz event: $eventType', 'QuizLogService');

    await _postWithRetry('student/quiz/log', payload, eventType);
  }

  /// Internal: POST with retry on network/server errors (not 4xx client errors)
  Future<void> _postWithRetry(
      String path, Map<String, dynamic> payload, String label) async {
    int attempt = 0;

    while (attempt <= _maxRetries) {
      try {
        await dio.post(path, data: payload);
        AppLogger.debug('Quiz event "$label" logged (attempt ${attempt + 1})',
            'QuizLogService');
        return;
      } on DioException catch (e) {
        final status = e.response?.statusCode;

        // Do not retry on client errors (4xx) — they won't change
        if (status != null && status >= 400 && status < 500) {
          AppLogger.error(
              'Quiz log "$label" rejected [$status]: ${e.response?.data}',
              'QuizLogService');
          return;
        }

        attempt++;
        if (attempt > _maxRetries) {
          AppLogger.error(
              'Quiz log "$label" failed after $_maxRetries retries: ${e.message}',
              'QuizLogService');
          return;
        }

        AppLogger.warning(
            'Quiz log "$label" attempt $attempt failed, retrying...',
            'QuizLogService');
        await Future.delayed(_retryDelay * attempt);
      } catch (e) {
        AppLogger.error(
            'Unexpected error logging "$label": $e', 'QuizLogService');
        return;
      }
    }
  }

  Future<void> logStart(String exerciseId) async {
    await logEvent(
        eventType: 'START', exerciseId: exerciseId, timestamp: DateTime.now());
  }

  Future<void> logSubmit(String exerciseId, int durationInSeconds) async {
    // Cegah double log SUBMIT untuk exercise yang sama
    final key = 'SUBMIT_$exerciseId';
    if (_submittedExercises.contains(key)) {
      AppLogger.warning(
          'SUBMIT already logged for exercise $exerciseId, skipping',
          'QuizLogService');
      return;
    }
    _submittedExercises.add(key);

    await logEvent(
      eventType: 'SUBMIT',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      durationInSeconds: durationInSeconds,
    );
  }

  Future<void> logAutoSubmit(String exerciseId, int durationInSeconds) async {
    // Cegah double log AUTO_SUBMIT untuk exercise yang sama
    final key = 'SUBMIT_$exerciseId';
    if (_submittedExercises.contains(key)) {
      AppLogger.warning(
          'AUTO_SUBMIT already logged for exercise $exerciseId, skipping',
          'QuizLogService');
      return;
    }
    _submittedExercises.add(key);

    await logEvent(
      eventType: 'AUTO_SUBMIT',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      durationInSeconds: durationInSeconds,
    );
  }

  Future<void> logSuspicious(String exerciseId, String reason) async {
    await logEvent(
      eventType: 'SUSPICIOUS_$reason',
      exerciseId: exerciseId,
      timestamp: DateTime.now(),
      suspiciousFlag: true,
    );
  }
}
