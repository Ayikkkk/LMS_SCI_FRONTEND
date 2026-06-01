import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/error_messages.dart';
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
      final message = ErrorMessages.fromDioException(
        e,
        fallback: 'Login gagal',
      );
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
      final message = ErrorMessages.fromDioException(
        e,
        fallback: 'Gagal mengubah password',
      );
      throw Exception(message);
    }
  }

  /// -----------------------
  /// GET TOKEN
  /// Jika secure storage gagal decrypt (misal setelah reinstall/clear data),
  /// hapus data korup dan return null agar user diminta login ulang.
  /// -----------------------
  Future<String?> getToken() async {
    try {
      return await storage.read(key: 'auth_token');
    } catch (_) {
      // Data terenkripsi korup — hapus semua dan minta login ulang
      try {
        await storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  /// -----------------------
  /// GET STUDENT DATA
  /// -----------------------
  Future<Map<String, dynamic>?> getStudentData() async {
    try {
      final raw = await storage.read(key: 'student_data');
      if (raw == null) return null;
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
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
