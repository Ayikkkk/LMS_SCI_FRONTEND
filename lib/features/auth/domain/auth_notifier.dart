import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthStatus.unknown) {
    checkAuthStatus();
  }

  /// Ambil token (optional untuk kebutuhan lain)
  Future<String?> getCurrentToken() async {
    return _repository.getToken();
  }

  /// Mengecek status login saat aplikasi dibuka
  Future<void> checkAuthStatus() async {
    final token = await _repository.getToken();

    if (token != null && token.isNotEmpty) {
      // Set header Authorization supaya request tidak gagal
      _repository.setDioAuthorizationHeader(token);

      state = AuthStatus.authenticated;
    } else {
      state = AuthStatus.unauthenticated;
    }
  }

  /// LOGIN
  Future<bool> doLogin(String username, String password) async {
    final success = await _repository.login(username, password);

    if (success) {
      // Ambil token baru
      final newToken = await _repository.getToken();

      if (newToken != null && newToken.isNotEmpty) {
        // SET Authorization header supaya dashboard bisa diakses
        _repository.setDioAuthorizationHeader(newToken);

        // Update state auth
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
      }
    }

    return success;
  }

  /// LOGOUT
  Future<void> doLogout() async {
    await _repository.logout();

    // Bersihkan header Authorization
    _repository.clearDioAuthorizationHeader();

    state = AuthStatus.unauthenticated;
  }

  /// RESET (hapus semua data lokal)
  Future<void> hardReset() async {
    await _repository.clearAllData();
    _repository.clearDioAuthorizationHeader();

    state = AuthStatus.unauthenticated;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
