// lib/core/constants/error_messages.dart

/// Error message constants for the LMS application
class ErrorMessages {
  // Private constructor to prevent instantiation
  ErrorMessages._();

  // ============================
  // GENERAL ERRORS
  // ============================
  static const String networkError = 'Tidak dapat terhubung ke server';
  static const String unknownError = 'Terjadi kesalahan yang tidak diketahui';
  static const String timeoutError = 'Koneksi timeout, silakan coba lagi';
  static const String serverError = 'Server sedang bermasalah';

  // ============================
  // AUTH ERRORS
  // ============================
  static const String loginFailed = 'Login gagal, periksa username dan password';
  static const String logoutFailed = 'Gagal logout';
  static const String changePasswordFailed = 'Gagal mengubah password';
  static const String unauthorized = 'Sesi Anda telah berakhir, silakan login kembali';

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
  static const String answerAllQuestions = 'Harap jawab semua pertanyaan sebelum menyelesaikan kuis';

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
  static const String copyToDownloadFailed = 'Gagal menyalin file ke folder Download';
}
