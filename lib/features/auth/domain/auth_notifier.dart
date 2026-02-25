import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/auth_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../laporan_harian/presentation/providers/laporan_provider.dart';
import '../../../../core/network/api_client.dart';
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
    await _repo.logout();

    // reset semua provider terkait user
    ref.invalidate(profileDataProvider);
    ref.invalidate(laporanCheckProvider);

    state = AuthStatus.unauthenticated;
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
/// This is the single source of truth for student data across the app
final studentProvider = Provider<StudentModel?>((ref) {
  final profileAsync = ref.watch(profileDataProvider);

  return profileAsync.maybeWhen(
    data: (profile) => profile,
    orElse: () => null,
  );
});
