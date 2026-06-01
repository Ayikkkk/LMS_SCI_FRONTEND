// lib/core/config/environment.dart

import 'package:flutter/foundation.dart';

/// Environment types for the application
enum Environment {
  development,
  staging,
  production,
}

/// Environment configuration class
/// Manages API URLs and environment-specific settings
class EnvironmentConfig {
  static Environment _environment = Environment.development;

  /// Set the current environment
  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Get current environment
  static Environment get currentEnvironment => _environment;

  /// Get API base URL based on current environment
  static String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        // Read from --dart-define=DEV_API_URL=http://192.168.x.x:8000/api/
        const devUrl = String.fromEnvironment(
          'DEV_API_URL',
          defaultValue: 'http://192.168.101.80:8000/api/',
        );
        return devUrl;

      case Environment.staging:
        return 'http://151.243.222.93:30083/api/';

      case Environment.production:
        return 'http://151.243.222.93:30083/api/';
    }
  }

  /// Get API host (without /api/)
  static String get apiHost {
    switch (_environment) {
      case Environment.development:
        const devHost = String.fromEnvironment(
          'DEV_API_HOST',
          defaultValue: 'http://192.168.101.80:8000',
        );
        return devHost;

      case Environment.staging:
        return 'http://151.243.222.93:30083';

      case Environment.production:
        return 'http://151.243.222.93:30083';
    }
  }

  /// Check if current environment is production
  static bool get isProduction => _environment == Environment.production;

  /// Check if current environment is development
  static bool get isDevelopment => _environment == Environment.development;

  /// Check if current environment is staging
  static bool get isStaging => _environment == Environment.staging;

  /// Get environment name as string
  static String get environmentName {
    switch (_environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  /// Get environment-specific timeout durations
  static Duration get connectTimeout {
    return _environment == Environment.development
        ? const Duration(seconds: 60) // Longer timeout for development
        : const Duration(seconds: 30);
  }

  static Duration get receiveTimeout {
    return _environment == Environment.development
        ? const Duration(seconds: 60)
        : const Duration(seconds: 30);
  }

  /// Enable/disable debug features based on environment
  static bool get enableDebugFeatures {
    return _environment != Environment.production;
  }

  /// Get app name with environment suffix
  static String getAppName(String baseName) {
    switch (_environment) {
      case Environment.development:
        return '$baseName (Dev)';
      case Environment.staging:
        return '$baseName (Staging)';
      case Environment.production:
        return baseName;
    }
  }

  /// Initialize environment from build configuration
  static void initialize() {
    // Read environment from build-time constant
    const envString = String.fromEnvironment(
      'ENV',
      defaultValue: 'development',
    );

    switch (envString.toLowerCase()) {
      case 'production':
      case 'prod':
        _environment = Environment.production;
        break;
      case 'staging':
      case 'stg':
        _environment = Environment.staging;
        break;
      case 'development':
      case 'dev':
      default:
        _environment = Environment.development;
        break;
    }
  }

  /// Print current configuration (for debugging)
  static void printConfig() {
    if (!enableDebugFeatures) return; // Don't print in production

    // Use single print for better formatting
    debugPrint('''
=================================
Environment Configuration
=================================
Environment: $environmentName
API Base URL: $apiBaseUrl
API Host: $apiHost
Is Production: $isProduction
Debug Features: $enableDebugFeatures
Connect Timeout: ${connectTimeout.inSeconds}s
Receive Timeout: ${receiveTimeout.inSeconds}s
=================================''');
  }
}
