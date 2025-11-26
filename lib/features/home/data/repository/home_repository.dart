// lib/features/home/data/repository/home_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:lms_frontend/features/home/data/models/dashboard_model.dart';
// Import dependencies yang diperlukan dari fitur Auth
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/student_model.dart';
// Import API Client Dio (Diasumsikan ada di core)
import '../../../../core/network/api_client.dart';

class HomeRepository {
  final AuthRepository _authRepository;
  final Dio _dio;

  HomeRepository(this._authRepository, this._dio);

  Future<DashboardModel> fetchDashboardData() async {

    // 1. Ambil Data Siswa (dari Secure Storage)
    final Map<String, dynamic>? studentJson = await _authRepository.getStudentData();

    if (studentJson == null) {
      throw Exception("Sesi siswa tidak ditemukan. Silakan login ulang.");
    }
    final StudentModel student = StudentModel.fromJson(studentJson);

    // 2. LAKUKAN PANGGILAN API UNTUK DATA DASHBOARD
    try {
      final response = await _dio.get('/student/dashboard');

      if (response.statusCode == 200 && response.data != null) {

        // 💡 PERBAIKAN KRITIS: Akses kunci 'data' dari respons API
        final Map<String, dynamic> responseBody = response.data as Map<String, dynamic>;

        if (responseBody.containsKey('data') == false || responseBody['data'] == null) {
             throw Exception("Format data API Dashboard kosong atau tidak valid setelah login.");
        }

        final Map<String, dynamic> data = responseBody['data'] as Map<String, dynamic>;

        // 3. Konversi Data API ke Model (sekarang mengakses dari Map 'data')

        // 💡 PERBAIKAN: Validasi kunci data utama yang HILANG DI LEVEL INI
        if (!data.containsKey('stats') || !data.containsKey('meetings_today')) {
             // Sekarang error ini akan muncul jika keys hilang di dalam 'data'
             throw Exception("Format data API Dashboard tidak lengkap (Kunci 'stats' atau 'meetings_today' hilang di dalam 'data').");
        }

        // Data 'stats'
        final Stats stats = Stats.fromJson(data['stats'] as Map<String, dynamic>);

        // Data 'meetings_today'
        final List<OnlineMeetingModel> meetings = (data['meetings_today'] as List)
            .map((m) => OnlineMeetingModel.fromJson(m as Map<String, dynamic>))
            .toList();

        // 4. Kembalikan DashboardModel
        return DashboardModel(
          student: student,
          stats: stats,
          meetingsToday: meetings,
        );
      }

      throw Exception("Gagal memuat data dashboard. Status code: ${response.statusCode}");

    } on DioException catch (e) {
      // ... (Penanganan DioException tetap sama)
      if (e.response?.statusCode == 401) {
        await _authRepository.logout();
        throw Exception("Sesi Anda telah berakhir. Silakan login kembali.");
      }
      final errorMessage = e.response?.data['message'] ?? e.message;
      print('Dio Error Dashboard: $errorMessage');
      throw Exception("Error API Dashboard: $errorMessage");

    } catch (e) {
      // ... (Penanganan error parsing tetap sama)
      print('Parsing atau Error Generic di HomeRepository: $e');
      throw Exception("Terjadi kesalahan saat memproses data. (${e.toString()})");
    }
  }
}
// Provider untuk HomeRepository
final homeRepositoryProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return HomeRepository(authRepository, dio);
});