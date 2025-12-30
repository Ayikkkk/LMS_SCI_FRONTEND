// lib/features/home/data/repository/home_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../../../course/data/models/assignment_model.dart';


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

      // Ambil langsung bagian "data" dari API
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(response.data['data'] ?? {});

      // Delegasikan parsing ke DashboardModel
      return DashboardModel.fromJson(data);
    } on DioException catch (e) {
      final message =
          e.response?.data['message'] ?? e.message ?? 'Unknown error';
      throw Exception('Dashboard API Error: $message');
    } catch (e) {
      throw Exception('Dashboard Parsing Error: $e');
    }
  }

  Future<List<AssignmentModel>> fetchAssignments() async {
  try {
    final response = await _dio.get('student/assignments');

    final dataList = (response.data['assignments'] as List? ?? [])
        .map((e) => AssignmentModel.fromJson(e))
        .toList();

    return dataList;
  } on DioException catch (e) {
    final message = e.response?.data['message'] ?? e.message ?? 'Unknown error';
    throw Exception('Assignments API Error: $message');
  } catch (e) {
    throw Exception('Assignments Parsing Error: $e');
  }
}

}