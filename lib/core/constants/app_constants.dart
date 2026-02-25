// lib/core/constants/app_constants.dart

/// Application-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ============================
  // APP INFO
  // ============================
  static const String appName = 'LMS Student';
  static const String appVersion = '1.0.0';

  // ============================
  // STORAGE KEYS
  // ============================
  static const String tokenKey = 'auth_token';
  static const String onboardingKey = 'has_seen_onboarding';
  static const String themeKey = 'theme_mode';

  // ============================
  // MEDIA STORE
  // ============================
  static const String mediaStoreFolder = 'LMS Student';

  // ============================
  // TIMEOUTS
  // ============================
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============================
  // PAGINATION
  // ============================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ============================
  // FILE UPLOAD
  // ============================
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileExtensions = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'jpg',
    'jpeg',
    'png',
    'mp4',
    'zip',
    'rar',
  ];
}
