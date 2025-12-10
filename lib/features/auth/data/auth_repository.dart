// lib/features/auth/data/auth_repository.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

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
      print("Login Error: ${e.response?.data ?? e.message}");
      return false;
    }
  }

  /// AMBIL TOKEN
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  /// AMBIL DATA USER
  Future<Map<String, dynamic>?> getStudentData() async {
    final raw = await storage.read(key: 'student_data');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// CLEAR HEADER TOKEN
  void clearHeader() {
    _dio.options.headers.remove('Authorization');
  }

  /// -----------------------
  /// LOGOUT
  /// -----------------------
  Future<void> logout() async {
    try {
      final token = await getToken();
      await _dio.post("/student/logout",
          options: Options(headers: {"Authorization": "Bearer $token"}));
    } catch (_) {}

    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'student_data');
    clearHeader();
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository(dio));
