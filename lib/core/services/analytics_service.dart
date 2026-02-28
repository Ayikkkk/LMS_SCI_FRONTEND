// lib/core/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

import '../config/environment.dart';
import '../utils/logger.dart';

/// Service for handling analytics tracking with Firebase Analytics
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// Initialize Analytics
  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;

      // Enable analytics collection based on environment
      await _analytics!.setAnalyticsCollectionEnabled(
        !EnvironmentConfig.isDevelopment, // Disable in development
      );

      // Set default parameters
      await _analytics!.setDefaultEventParameters({
        'environment': EnvironmentConfig.environmentName,
        'api_url': EnvironmentConfig.apiBaseUrl,
      });

      // Create observer for navigation tracking
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      AppLogger.success('Analytics initialized', 'AnalyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to initialize Analytics', e, null, 'AnalyticsService');
    }
  }

  /// Get analytics observer for navigation tracking
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// Check if analytics is enabled
  static bool get isEnabled => _analytics != null;

  // ==================== USER EVENTS ====================

  /// Track user login
  static Future<void> logLogin({
    required String method,
    String? userId,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logLogin(loginMethod: method);
      AppLogger.debug('Login tracked: $method', 'AnalyticsService');
    } catch (e) {
      AppLogger.error('Failed to log login', e, null, 'AnalyticsService');
    }
  }

  /// Track user logout
  static Future<void> logLogout() async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(name: 'logout');
      AppLogger.debug('Logout tracked', 'AnalyticsService');
    } catch (e) {
      AppLogger.error('Failed to log logout', e, null, 'AnalyticsService');
    }
  }

  /// Set user ID
  static Future<void> setUserId(String userId) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserId(id: userId);
      AppLogger.debug('User ID set: $userId', 'AnalyticsService');
    } catch (e) {
      AppLogger.error('Failed to set user ID', e, null, 'AnalyticsService');
    }
  }

  /// Set user properties
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      AppLogger.error(
          'Failed to set user property', e, null, 'AnalyticsService');
    }
  }

  /// Clear user data (on logout)
  static Future<void> clearUserData() async {
    if (_analytics == null) return;

    try {
      await _analytics!.setUserId(id: null);
      AppLogger.debug('User data cleared', 'AnalyticsService');
    } catch (e) {
      AppLogger.error('Failed to clear user data', e, null, 'AnalyticsService');
    }
  }

  // ==================== QUIZ EVENTS ====================

  /// Track quiz start
  static Future<void> logQuizStart({
    required String quizId,
    required String quizName,
    required String quizType,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'quiz_start',
        parameters: {
          'quiz_id': quizId,
          'quiz_name': quizName,
          'quiz_type': quizType,
        },
      );
      AppLogger.debug('Quiz start tracked: $quizName', 'AnalyticsService');
    } catch (e) {
      AppLogger.error('Failed to log quiz start', e, null, 'AnalyticsService');
    }
  }

  /// Track quiz completion
  static Future<void> logQuizComplete({
    required String quizId,
    required String quizName,
    required String quizType,
    int? score,
    required int duration, // in seconds
    required int totalQuestions,
    required int answeredQuestions,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'quiz_complete',
        parameters: {
          'quiz_id': quizId,
          'quiz_name': quizName,
          'quiz_type': quizType,
          'score': score ?? 0,
          'duration_seconds': duration,
          'total_questions': totalQuestions,
          'answered_questions': answeredQuestions,
          'completion_rate': (answeredQuestions / totalQuestions * 100).round(),
        },
      );
      AppLogger.debug('Quiz complete tracked: $quizName', 'AnalyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to log quiz complete', e, null, 'AnalyticsService');
    }
  }

  /// Track quiz abandon
  static Future<void> logQuizAbandon({
    required String quizId,
    required String quizName,
    required int answeredQuestions,
    required int totalQuestions,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'quiz_abandon',
        parameters: {
          'quiz_id': quizId,
          'quiz_name': quizName,
          'answered_questions': answeredQuestions,
          'total_questions': totalQuestions,
        },
      );
    } catch (e) {
      AppLogger.error(
          'Failed to log quiz abandon', e, null, 'AnalyticsService');
    }
  }

  // ==================== ASSIGNMENT EVENTS ====================

  /// Track assignment view
  static Future<void> logAssignmentView({
    required String assignmentId,
    required String assignmentName,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'assignment_view',
        parameters: {
          'assignment_id': assignmentId,
          'assignment_name': assignmentName,
        },
      );
    } catch (e) {
      AppLogger.error(
          'Failed to log assignment view', e, null, 'AnalyticsService');
    }
  }

  /// Track assignment submit
  static Future<void> logAssignmentSubmit({
    required String assignmentId,
    required String assignmentName,
    required String submissionType, // file, text, etc
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'assignment_submit',
        parameters: {
          'assignment_id': assignmentId,
          'assignment_name': assignmentName,
          'submission_type': submissionType,
        },
      );
      AppLogger.debug(
          'Assignment submit tracked: $assignmentName', 'AnalyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to log assignment submit', e, null, 'AnalyticsService');
    }
  }

  // ==================== ONLINE CLASS EVENTS ====================

  /// Track online class join
  static Future<void> logOnlineClassJoin({
    required String classId,
    required String className,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'online_class_join',
        parameters: {
          'class_id': classId,
          'class_name': className,
        },
      );
      AppLogger.debug(
          'Online class join tracked: $className', 'AnalyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to log online class join', e, null, 'AnalyticsService');
    }
  }

  /// Track online class leave
  static Future<void> logOnlineClassLeave({
    required String classId,
    required String className,
    required int duration, // in seconds
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'online_class_leave',
        parameters: {
          'class_id': classId,
          'class_name': className,
          'duration_seconds': duration,
        },
      );
    } catch (e) {
      AppLogger.error(
          'Failed to log online class leave', e, null, 'AnalyticsService');
    }
  }

  // ==================== CONTENT EVENTS ====================

  /// Track content view
  static Future<void> logContentView({
    required String contentId,
    required String contentName,
    required String contentType, // video, pdf, article, etc
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'content_view',
        parameters: {
          'content_id': contentId,
          'content_name': contentName,
          'content_type': contentType,
        },
      );
    } catch (e) {
      AppLogger.error(
          'Failed to log content view', e, null, 'AnalyticsService');
    }
  }

  /// Track file download
  static Future<void> logFileDownload({
    required String fileId,
    required String fileName,
    required String fileType,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'file_download',
        parameters: {
          'file_id': fileId,
          'file_name': fileName,
          'file_type': fileType,
        },
      );
    } catch (e) {
      AppLogger.error(
          'Failed to log file download', e, null, 'AnalyticsService');
    }
  }

  // ==================== SCREEN TRACKING ====================

  /// Track screen view
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      AppLogger.error('Failed to log screen view', e, null, 'AnalyticsService');
    }
  }

  // ==================== CUSTOM EVENTS ====================

  /// Log custom event
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
      AppLogger.debug('Custom event tracked: $name', 'AnalyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to log custom event', e, null, 'AnalyticsService');
    }
  }

  // ==================== ERROR TRACKING ====================

  /// Track error event
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    if (_analytics == null) return;

    try {
      await _analytics!.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage,
          'stack_trace': stackTrace ?? 'N/A',
        },
      );
    } catch (e) {
      AppLogger.error('Failed to log error event', e, null, 'AnalyticsService');
    }
  }
}
