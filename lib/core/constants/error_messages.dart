// lib/core/constants/error_messages.dart

import 'package:dio/dio.dart';

/// Error message constants for the LMS application
class ErrorMessages {
  // Private constructor to prevent instantiation
  ErrorMessages._();

  // ============================
  // GENERAL ERRORS
  // ============================
  static const String networkError =
      'Tidak ada koneksi internet. Periksa koneksi HP Anda lalu coba lagi.';
  static const String unknownError =
      'Aplikasi sedang bermasalah atau dalam perbaikan. Silakan coba lagi nanti.';
  static const String timeoutError = networkError;
  static const String serverError = unknownError;

  // ============================
  // AUTH ERRORS
  // ============================
  static const String loginFailed =
      'Login gagal, periksa username dan password';
  static const String logoutFailed = 'Gagal logout';
  static const String changePasswordFailed = 'Gagal mengubah password';
  static const String unauthorized =
      'Sesi Anda telah berakhir, silakan login kembali';

  // ============================
  // COURSE ERRORS
  // ============================
  static const String fetchMaterialsFailed = 'Gagal memuat materi';
  static const String fetchAssignmentsFailed = 'Gagal memuat daftar tugas';
  static const String fetchMaterialDetailFailed = 'Gagal memuat detail materi';
  static const String fetchAssignmentDetailFailed = 'Gagal memuat detail tugas';
  static const String submitTaskFailed = 'Gagal mengirim tugas';

  // ============================
  // QUIZ ERRORS
  // ============================
  static const String fetchQuizFailed = 'Gagal memuat soal quiz';
  static const String submitQuizFailed = 'Gagal mengirim jawaban quiz';
  static const String fetchResultFailed = 'Gagal memuat hasil quiz';
  static const String answerAllQuestions =
      'Harap jawab semua pertanyaan sebelum menyelesaikan kuis';

  // ============================
  // PROFILE ERRORS
  // ============================
  static const String fetchProfileFailed = 'Gagal memuat profil';

  // ============================
  // DASHBOARD ERRORS
  // ============================
  static const String fetchDashboardFailed = 'Gagal memuat dashboard';

  // ============================
  // GRADES ERRORS
  // ============================
  static const String fetchGradesFailed = 'Gagal memuat nilai';

  // ============================
  // LAPORAN HARIAN ERRORS
  // ============================
  static const String fetchLaporanFailed = 'Gagal memuat laporan harian';
  static const String submitLaporanFailed = 'Gagal mengirim laporan harian';

  // ============================
  // FILE ERRORS
  // ============================
  static const String downloadFailed = 'Gagal mengunduh file';
  static const String fileNotFound = 'File tidak ditemukan';
  static const String copyToDownloadFailed =
      'Gagal menyalin file ke folder Download';

  static String fromException(Object error, {String? fallback}) {
    if (error is DioException) {
      return fromDioException(error, fallback: fallback);
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message == networkError || message == unknownError) {
      return message;
    }

    if (message.isNotEmpty && !_looksTechnical(message)) {
      return message;
    }

    return fallback ?? unknownError;
  }

  static String fromDioException(DioException error, {String? fallback}) {
    if (_isConnectionProblem(error)) {
      return networkError;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return unauthorized;
    }

    if (statusCode == 400 ||
        statusCode == 403 ||
        statusCode == 404 ||
        statusCode == 422) {
      return _messageFromResponse(error.response?.data) ??
          fallback ??
          unknownError;
    }

    return fallback ?? unknownError;
  }

  static bool _isConnectionProblem(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.response == null;
  }

  static String? _messageFromResponse(dynamic data) {
    if (data is! Map) return null;

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
      return first.toString();
    }

    return data['message']?.toString();
  }

  static bool _looksTechnical(String message) {
    final lower = message.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('formatexception') ||
        lower.contains('type ') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('stack trace') ||
        lower.contains('api error') ||
        lower.contains('parsing error') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection reset');
  }
}
