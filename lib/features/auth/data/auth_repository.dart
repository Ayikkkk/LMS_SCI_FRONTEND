import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  static const FlutterSecureStorage storage = FlutterSecureStorage();

  /// LOGIN
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/student/login', data: {
        'username': username,
        'password': password,
        'device_name': 'mobile_app',
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final student = jsonEncode(response.data['student']);

        // simpan token
        await storage.write(key: 'auth_token', value: token);
        await storage.write(key: 'student_data', value: student);

        // set header
        _dio.options.headers['Authorization'] = 'Bearer $token';

        return true;
      }
      return false;
    } on DioException catch (e) {
      print('Login Error: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  /// Ambil token
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  /// Set header Authorization
  void setDioAuthorizationHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Hapus header Authorization
  void clearDioAuthorizationHeader() {
    _dio.options.headers.remove('Authorization');
  }

  /// Ambil data student
  Future<Map<String, dynamic>?> getStudentData() async {
    final dataString = await storage.read(key: 'student_data');
    if (dataString != null) {
      return jsonDecode(dataString);
    }
    return null;
  }

  /// LOGOUT
  Future<void> logout() async {
    try {
      await _dio.post('/student/logout',
          options: Options(
              headers: {'Authorization': 'Bearer ${await getToken()}'}));
    } catch (e) {
      print('Logout API failed but clearing local data...');
    }

    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'student_data');

    // Hapus header
    clearDioAuthorizationHeader();
  }

  /// Reset app (digunakan untuk testing/debug)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    await storage.delete(key: 'auth_token');
    await prefs.remove('has_seen_onboarding');
  }
}

// Provider
final authRepositoryProvider =
    Provider((ref) => AuthRepository(dio));
