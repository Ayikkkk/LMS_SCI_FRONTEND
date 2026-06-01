// lib/core/constants/api_endpoints.dart

/// API endpoint constants for the LMS application
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // ============================
  // AUTH ENDPOINTS
  // ============================
  static const String login = '/login';
  static const String logout = '/logout';
  static const String changePassword = '/change-password';

  // ============================
  // STUDENT ENDPOINTS
  // ============================
  static const String profile = '/student/profile';
  static const String materials = '/student/materials';
  static const String assignments = '/student/assignments';

  // Dynamic endpoints
  static String materialDetail(int id) => '/student/posts/$id';
  static String assignmentDetail(int id) => '/student/assignments/$id';
  static String assignmentStatus(int id) => '/student/assignment/$id/status';
  static String submitTask = '/student/submit-task';
  static String updateTask(int id) => '/student/submit-task/$id/update';
  static String taskSubmissionDownload(int id) => '/student/tasks/$id/download';

  // ============================
  // EXERCISE/QUIZ ENDPOINTS
  // ============================
  static String exerciseDetail(String id) => '/student/exercises/$id';
  static String exerciseSubmit(String id) => '/student/exercises/$id/submit';
  static String exerciseResult(String id) => '/student/exercises/$id/result';

  // ============================
  // DASHBOARD ENDPOINTS
  // ============================
  static const String dashboard = '/student/dashboard';
  static const String dashboardAssignments = '/student/dashboard/assignments';

  // ============================
  // GRADES ENDPOINTS
  // ============================
  static const String grades = '/student/grades';
  static const String gradeRecap = '/student/grades/recap';

  // ============================
  // LAPORAN HARIAN ENDPOINTS
  // ============================
  static const String laporanCheck = '/student/laporan/check';
  static const String laporanSubmit = '/student/laporan/submit';

  // ============================
  // ONLINE CLASS ENDPOINTS
  // ============================
  static const String onlineMeetings = '/student/online-meetings';
}
