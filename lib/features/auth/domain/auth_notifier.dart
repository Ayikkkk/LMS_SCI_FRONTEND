// lib/features/auth/domain/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../profile/presentation/providers/profile_provider.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;
  final Ref ref;

  AuthNotifier(this.ref, this._repository) : super(AuthStatus.unknown) {
    checkAuthStatus();
  }

  /// Ambil token
  Future<String?> getCurrentToken() async {
    return _repository.getToken();
  }

  /// Cek status login
  Future<void> checkAuthStatus() async {
    final token = await _repository.getToken();

    if (token != null && token.isNotEmpty) {
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
      final newToken = await _repository.getToken();

      if (newToken != null && newToken.isNotEmpty) {
        _repository.setDioAuthorizationHeader(newToken);

        // REFRESH DATA PROFIL
        ref.invalidate(profileDataProvider);

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

    // REFRESH PROFIL
    ref.invalidate(profileDataProvider);

    state = AuthStatus.unauthenticated;
  }

  /// RESET APP
  Future<void> hardReset() async {
    await _repository.clearAllData();
    _repository.clearDioAuthorizationHeader();

    ref.invalidate(profileDataProvider);

    state = AuthStatus.unauthenticated;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref, ref.watch(authRepositoryProvider));
});
