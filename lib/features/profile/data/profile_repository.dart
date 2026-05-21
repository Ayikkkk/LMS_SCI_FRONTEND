// lib/features/profile/data/profile_repository.dart
import 'package:dio/dio.dart';
import '../../auth/data/repository/auth_repository.dart';

class ProfileRepository {
  final Dio _dio;
  final AuthRepository _authRepo;

  ProfileRepository(this._dio, this._authRepo);

  Future<Map<String, dynamic>> getProfile() async {
    final token = await _authRepo.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    final response = await _dio.get(
      '/student/profile',
      options: Options(headers: {
        "Authorization": "Bearer $token",
      }),
    );

    return response.data;
  }

  /// Update profile via POST ke /profile/update (multipart/form-data).
  /// Laravel tidak bisa parse multipart dari PUT — pakai POST dengan endpoint terpisah.
  Future<Map<String, dynamic>> updateProfile(
    FormData formData, {
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  }) async {
    final token = await _authRepo.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    // Pastikan tidak ada _method override
    formData.fields.removeWhere((entry) => entry.key == '_method');

    final response = await _dio.post(
      '/student/profile/update',
      data: formData,
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
      onSendProgress: onSendProgress,
    );

    return response.data;
  }

  Future<void> deletePhoto() async {
    final token = await _authRepo.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    await _dio.delete(
      '/student/photo',
      options: Options(headers: {
        "Authorization": "Bearer $token",
      }),
    );
  }

  Future<void> changePassword(String oldPass, String newPass) async {
    final token = await _authRepo.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    await _dio.post(
      '/student/change-password',
      data: {
        "old_password": oldPass,
        "new_password": newPass,
      },
      options: Options(headers: {
        "Authorization": "Bearer $token",
      }),
    );
  }
}
