// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

/// Application logger utility
/// Provides consistent logging across the app
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Log informational messages
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('ℹ️ $prefix $message');
    }
  }

  /// Log success messages
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('✅ $prefix $message');
    }
  }

  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('❌ $prefix $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  /// Log warning messages
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('⚠️ $prefix $message');
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '';
      debugPrint('🔍 $prefix $message');
    }
  }

  /// Log network requests
  static void network(String method, String url, [int? statusCode]) {
    if (kDebugMode) {
      final status = statusCode != null ? ' [$statusCode]' : '';
      debugPrint('🌐 $method $url$status');
    }
  }

  /// Log download operations
  static void download(String message) {
    if (kDebugMode) {
      debugPrint('⬇️ $message');
    }
  }
}
