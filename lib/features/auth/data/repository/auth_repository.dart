import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  /// -----------------------
  /// LOGIN
  /// -----------------------
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/student/login', data: {
        'username': username,
        'password': password,
        'device_name': 'mobile_app',
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final studentJson = jsonEncode(response.data['student']);

        await storage.write(key: 'auth_token', value: token);
        await storage.write(key: 'student_data', value: studentJson);

        _dio.options.headers['Authorization'] = 'Bearer $token';
        return true;
      }

      return false;
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Login gagal';
      throw Exception(message);
    }
  }

  /// -----------------------
  /// CHANGE PASSWORD
  /// -----------------------
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post('/student/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Gagal mengubah password';
      throw Exception(message);
    }
  }

  /// -----------------------
  /// GET TOKEN
  /// -----------------------
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  /// -----------------------
  /// GET STUDENT DATA
  /// -----------------------
  Future<Map<String, dynamic>?> getStudentData() async {
    final raw = await storage.read(key: 'student_data');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// -----------------------
  /// CLEAR HEADER TOKEN
  /// -----------------------
  void clearHeader() {
    _dio.options.headers.remove('Authorization');
  }

  /// -----------------------
  /// LOGOUT
  /// -----------------------
  Future<void> logout() async {
    try {
      await _dio.post('/student/logout');
    } catch (_) {}

    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'student_data');
    clearHeader();
  }
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(dio));
