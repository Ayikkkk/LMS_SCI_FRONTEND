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

  /// Update profile.
  /// IMPORTANT: Use POST with `_method=PUT` in FormData so PHP/Laravel receives file.
  Future<Map<String, dynamic>> updateProfile(
    FormData formData, {
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  }) async {
    final token = await _authRepo.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    // Ensure method override so Laravel can treat it as PUT but still parse files
    // If caller already added _method, do not duplicate
    final hasMethodOverride =
        formData.fields.any((entry) => entry.key == '_method');
    if (!hasMethodOverride) {
      formData.fields.add(MapEntry('_method', 'PUT'));
    }

    final response = await _dio.post(
      '/student/profile', // POST with _method=PUT
      data: formData,
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          // Content-Type will be set by Dio for FormData automatically,
          // but explicit is OK as well.
          "Content-Type": "multipart/form-data",
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
