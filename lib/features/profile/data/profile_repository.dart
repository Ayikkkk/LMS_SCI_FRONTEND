import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

class ProfileRepository {
  final Dio _dio;
  final AuthRepository _authRepo;

  ProfileRepository(this._dio, this._authRepo);

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _authRepo.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Token tidak ditemukan. Silakan login ulang.");
    }

    final response = await _dio.get(
      '/student/profile',
      options: Options(
        headers: {"Authorization": "Bearer $token"},
      ),
    );

    return response.data;
  }
}

final profileRepositoryProvider = Provider((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  return ProfileRepository(dio, authRepo);
});
