import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/auth_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../laporan_harian/presentation/providers/laporan_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/crashlytics_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/utils/logger.dart';
import '../data/models/student_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repo;
  final Ref ref;

  AuthNotifier(this.ref, this._repo) : super(AuthStatus.unknown);

  /// ==========================
  /// CEK STATUS LOGIN
  /// ==========================
  Future<void> checkAuthStatus() async {
    final token = await _repo.getToken();

    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = "Bearer $token";
      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  /// ==========================
  /// LOGIN
  /// ==========================
  Future<bool> doLogin(String username, String password) async {
    try {
      final success = await _repo.login(username, password);

      if (success) {
        final token = await _repo.getToken();
        if (token != null) {
          dio.options.headers['Authorization'] = "Bearer $token";
        }

        // refresh provider terkait user
        ref.invalidate(profileDataProvider);
        ref.invalidate(laporanCheckProvider);

        state = AuthStatus.authenticated;

        // Set user identifier for Crashlytics
        final student = ref.read(studentProvider);
        if (student != null) {
          await CrashlyticsService.setUserIdentifier(student.id.toString());
          await CrashlyticsService.setCustomKey('student_name', student.name);
          await CrashlyticsService.setCustomKey(
              'student_nis', student.nis ?? '');

          // Track login event in Analytics
          await AnalyticsService.logLogin(
            method: 'username_password',
            userId: student.id.toString(),
          );
          await AnalyticsService.setUserId(student.id.toString());
          await AnalyticsService.setUserProperty(
            name: 'student_name',
            value: student.name,
          );
          await AnalyticsService.setUserProperty(
            name: 'class_name',
            value: student.className ?? 'Unknown',
          );
        }
      }

      return success;
    } catch (e) {
      rethrow; // ⬅️ biar UI bisa tampilkan pesan error
    }
  }

  /// ==========================
  /// CHANGE PASSWORD
  /// ==========================
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    // 🔐 OPSIONAL (AKTIFKAN JIKA MAU AUTO LOGOUT)
    // await doLogout();
  }

  /// ==========================
  /// LOGOUT
  /// ==========================
  Future<void> doLogout() async {
    // Set state unauthenticated PERTAMA agar semua widget stop watching
    state = AuthStatus.unauthenticated;

    // Hapus Authorization header segera agar request in-flight tidak retry
    dio.options.headers.remove('Authorization');

    // Invalidate provider agar berhenti firing request
    ref.invalidate(profileDataProvider);
    ref.invalidate(laporanCheckProvider);

    // Baru lakukan cleanup async
    await _repo.logout();

    await AnalyticsService.logLogout();
    await AnalyticsService.clearUserData();
    await CrashlyticsService.clearUserIdentifier();
  }
}

/// ============================
/// PROVIDERS
/// ============================

/// PROVIDER UTAMA AUTH
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref, ref.read(authRepositoryProvider));
});

/// PROVIDER GLOBAL DATA SISWA LOGIN
/// Single source of truth for student data across the app.
/// Returns null while loading or if profile fetch fails.
final studentProvider = Provider<StudentModel?>((ref) {
  final profileAsync = ref.watch(profileDataProvider);

  return profileAsync.when(
    data: (profile) => profile,
    loading: () => null,
    error: (e, _) {
      AppLogger.warning(
          'studentProvider: profile fetch failed — $e', 'AuthNotifier');
      return null;
    },
  );
});
