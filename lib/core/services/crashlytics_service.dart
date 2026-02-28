// lib/core/services/crashlytics_service.dart

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../config/environment.dart';
import '../utils/logger.dart';

/// Service for handling crash reporting with Firebase Crashlytics
class CrashlyticsService {
  static FirebaseCrashlytics? _crashlytics;

  /// Initialize Crashlytics
  static Future<void> initialize() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable Crashlytics collection based on environment
      await _crashlytics!.setCrashlyticsCollectionEnabled(
        !EnvironmentConfig.isDevelopment, // Disable in development
      );

      // Set custom keys for better debugging
      await _crashlytics!
          .setCustomKey('environment', EnvironmentConfig.environmentName);
      await _crashlytics!.setCustomKey('api_url', EnvironmentConfig.apiBaseUrl);

      AppLogger.success('Crashlytics initialized', 'CrashlyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to initialize Crashlytics', e, null, 'CrashlyticsService');
    }
  }

  /// Log a non-fatal error
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      if (EnvironmentConfig.enableDebugFeatures) {
        AppLogger.error(
          'Crashlytics recorded error: ${reason ?? exception.toString()}',
          exception,
          stackTrace,
          'CrashlyticsService',
        );
      }
    } catch (e) {
      AppLogger.error('Failed to record error to Crashlytics', e, null,
          'CrashlyticsService');
    }
  }

  /// Log a message
  static Future<void> log(String message) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.log(message);
    } catch (e) {
      AppLogger.error(
          'Failed to log to Crashlytics', e, null, 'CrashlyticsService');
    }
  }

  /// Set user identifier
  static Future<void> setUserIdentifier(String userId) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier(userId);
      AppLogger.debug('User identifier set: $userId', 'CrashlyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to set user identifier', e, null, 'CrashlyticsService');
    }
  }

  /// Set custom key-value pair
  static Future<void> setCustomKey(String key, dynamic value) async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.setCustomKey(key, value);
    } catch (e) {
      AppLogger.error(
          'Failed to set custom key', e, null, 'CrashlyticsService');
    }
  }

  /// Clear user identifier (on logout)
  static Future<void> clearUserIdentifier() async {
    if (_crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier('');
      AppLogger.debug('User identifier cleared', 'CrashlyticsService');
    } catch (e) {
      AppLogger.error(
          'Failed to clear user identifier', e, null, 'CrashlyticsService');
    }
  }

  /// Force a crash (for testing only)
  static void forceCrash() {
    if (EnvironmentConfig.isProduction) {
      AppLogger.warning(
          'Cannot force crash in production', 'CrashlyticsService');
      return;
    }

    AppLogger.warning('Forcing crash for testing...', 'CrashlyticsService');
    _crashlytics!.crash();
  }

  /// Check if Crashlytics is enabled
  static bool get isEnabled => _crashlytics != null;

  /// Check if crash collection is enabled
  static Future<bool> isCrashlyticsCollectionEnabled() async {
    if (_crashlytics == null) return false;
    return _crashlytics!.isCrashlyticsCollectionEnabled;
  }
}
