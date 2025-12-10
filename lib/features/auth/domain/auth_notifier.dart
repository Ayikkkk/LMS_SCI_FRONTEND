// lib/features/auth/domain/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import '../../laporan_harian/presentation/providers/laporan_provider.dart';
import '../../../../core/network/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repo;
  final Ref ref;

  AuthNotifier(this.ref, this._repo) : super(AuthStatus.unknown) {
    checkAuthStatus();
  }

  /// CEK STATUS LOGIN SAAT APLIKASI DIBUKA
  Future<void> checkAuthStatus() async {
    final token = await _repo.getToken();

    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = "Bearer $token";
      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  /// LOGIN
  Future<bool> doLogin(String username, String password) async {
    final success = await _repo.login(username, password);

    if (success) {
      // SET HEADER TOKEN BARU
      final token = await _repo.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = "Bearer $token";
      }

      // INVALIDATE SEMUA PROVIDER YANG BERGANTUNG PADA USER
      ref.invalidate(profileDataProvider);
      ref.invalidate(laporanCheckProvider);

      state = AuthStatus.authenticated;
    }

    return success;
  }

  /// LOGOUT
  Future<void> doLogout() async {
    await _repo.logout();

    // RESET PROVIDER YANG BERISI DATA USER
    ref.invalidate(profileDataProvider);
    ref.invalidate(laporanCheckProvider);

    state = AuthStatus.unauthenticated;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref, ref.read(authRepositoryProvider));
});
