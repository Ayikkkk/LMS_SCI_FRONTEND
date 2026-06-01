// lib/features/home/data/repository/home_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/error_messages.dart';
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
      throw Exception(ErrorMessages.fromDioException(e));
    } catch (e) {
      throw Exception(ErrorMessages.unknownError);
    }
  }

  Future<List<AssignmentModel>> fetchAssignments(
      {int page = 1, int perPage = 15}) async {
    try {
      final response = await _dio.get(
        'student/assignments',
        queryParameters: {'page': page, 'per_page': perPage},
      );

      final dataList = (response.data['assignments'] as List? ?? [])
          .map((e) => AssignmentModel.fromJson(e))
          .toList();

      return dataList;
    } on DioException catch (e) {
      throw Exception(ErrorMessages.fromDioException(e));
    } catch (e) {
      throw Exception(ErrorMessages.unknownError);
    }
  }
}
