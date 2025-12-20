// lib/features/home/data/repository/home_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../../../auth/data/models/student_model.dart';

// ===============================================
// PROVIDER
// ===============================================

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return HomeRepository(dio);
});

// ===============================================
// REPOSITORY
// ===============================================

class HomeRepository {
  final Dio _dio;

  HomeRepository(this._dio);

  Future<DashboardModel> fetchDashboardData() async {
    try {
      final response = await _dio.get('student/dashboard');

      final Map<String, dynamic> body =
          Map<String, dynamic>.from(response.data);

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(body['data'] ?? {});

      // ================= STUDENT =================
      final Map<String, dynamic> studentJson =
          Map<String, dynamic>.from(data['student'] ?? {});

      final student = StudentModel.fromJson(studentJson);

      // ================= STATS =================
      final stats =
          Stats.fromJson(Map<String, dynamic>.from(data['stats'] ?? {}));

      // ================= MEETINGS =================
      final List<OnlineMeetingModel> meetings =
          (data['meetings_today'] as List? ?? [])
              .map((e) =>
                  OnlineMeetingModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

      return DashboardModel(
        student: student,
        stats: stats,
        meetingsToday: meetings,
      );
    } on DioException catch (e) {
      final msg = e.response?.data.toString() ?? e.message;
      throw Exception('Dashboard API Error: $msg');
    } catch (e) {
      throw Exception('Dashboard Parsing Error: $e');
    }
  }
}
