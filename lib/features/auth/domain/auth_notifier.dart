import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

// Enum untuk mendefinisikan status autentikasi
enum AuthStatus {
  unknown, // Status awal, sedang dicek
  authenticated, // Sudah login dan memiliki token valid
  unauthenticated // Belum login atau token tidak valid/dihapus
}

// State Notifier utama yang menyimpan status autentikasi
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;

  // Konstruktor: menerima AuthRepository dan memulai dengan status 'unknown'
  AuthNotifier(this._repository) : super(AuthStatus.unknown) {
    // Panggil fungsi ini saat AuthNotifier dibuat pertama kali
    checkAuthStatus();
  }

  // 💡 PERBAIKAN: Method baru untuk mendapatkan token (dipanggil dari UI/Repository lain)
  Future<String?> getCurrentToken() async {
    return _repository.getToken();
  }

  // Fungsi untuk memeriksa apakah token ada di secure storage
  Future<void> checkAuthStatus() async {
    final token = await _repository.getToken();
    if (token != null) {
      // 💡 PERBAIKAN KRITIS: Set header Dio agar request pertama Dashboard tidak gagal
      _repository.setDioAuthorizationHeader(token);

      // Jika token ada, set status menjadi authenticated
      state = AuthStatus.authenticated;
    } else {
      // Jika token tidak ada, set status menjadi unauthenticated
      state = AuthStatus.unauthenticated;
    }
  }

  // Fungsi yang dipanggil saat user menekan tombol Login
  Future<bool> doLogin(String username, String password) async {
    final success = await _repository.login(username, password);

    if (success) {
      // Jika login API sukses, ubah status menjadi authenticated
      state = AuthStatus.authenticated;
    }
    return success;
  }

  // Fungsi yang dipanggil saat user Logout
  Future<void> doLogout() async {
    await _repository.logout();
    state = AuthStatus.unauthenticated;
  }

  Future<void> hardReset() async {
    await _repository.logout();
    await _repository
        .clearAllData();
    state = AuthStatus.unauthenticated;
  }
}

// Provider yang menyediakan instance AuthNotifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  // Asumsi authRepositoryProvider tersedia
  return AuthNotifier(ref.watch(authRepositoryProvider));
});