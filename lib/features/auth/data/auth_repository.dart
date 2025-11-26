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

  /**
   * Mengirim kredensial ke API Laravel dan menyimpan token
   */
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

        await storage.write(key: 'auth_token', value: token);
        await storage.write(key: 'student_data', value: student);

        // ✅ Sudah benar: Atur header Dio untuk request berikutnya
        _dio.options.headers['Authorization'] = 'Bearer $token';

        return true;
      }
      return false;
    } on DioException catch (e) {
      print('Login Error: ${e.response?.data ?? e.message}');
      return false;
    }
  }

  /**
   * Mengambil token dari penyimpanan lokal
   */
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  // 💡 FUNGSI BARU: Menyusun header Dio dari token yang tersimpan
  void setDioAuthorizationHeader(String token) {
     _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /**
   * Mengambil data siswa yang tersimpan (misalnya untuk ditampilkan di Profile)
   */
  Future<Map<String, dynamic>?> getStudentData() async {
    final dataString = await storage.read(key: 'student_data');
    if (dataString != null) {
      return jsonDecode(dataString);
    }
    return null;
  }

  /**
   * Melakukan logout (memanggil API Laravel dan menghapus data lokal)
   */
  Future<void> logout() async {
    try {
      // Pastikan Dio masih memiliki token saat memanggil /logout
      await _dio.post('/student/logout',
          options: Options(
              headers: {'Authorization': 'Bearer ${await getToken()}'}));
    } catch (e) {
      print('Logout API failed but proceeding to clear local data: $e');
    }

    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'student_data');

    // ✅ Sudah benar: Hapus header Authorization
    _dio.options.headers.remove('Authorization');
  }

  Future<void> clearAllData() async {
    final prefs =
        await SharedPreferences.getInstance();

    await storage.delete(key: 'auth_token');
    await prefs.remove('has_seen_onboarding');
  }
}

// Provider untuk menyediakan instance AuthRepository (digunakan oleh AuthNotifier)
final authRepositoryProvider = Provider((ref) => AuthRepository(dio));