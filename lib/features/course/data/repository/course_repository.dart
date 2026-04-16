// lib/features/course/data/repository/course_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/utils/logger.dart';
import '../models/assignment_model.dart';
import '../models/course_material_model.dart';

class CourseRepository {
  final Dio _dio;
  CourseRepository(this._dio);

  ///  Ambil daftar materi siswa
  Future<List<CourseMaterialModel>> fetchMaterials(
      {int page = 1, int perPage = 15}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.materials,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final List<dynamic> data = response.data['materials'] ?? [];
      return data
          .map((e) => CourseMaterialModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      AppLogger.error(
        ErrorMessages.fetchMaterialsFailed,
        e.response?.data ?? e.message,
        null,
        'CourseRepository',
      );
      throw Exception(ErrorMessages.fetchMaterialsFailed);
    }
  }

  ///  Ambil daftar tugas siswa
  Future<List<AssignmentModel>> fetchAssignments(
      {int page = 1, int perPage = 15}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.assignments,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final List<dynamic> data = response.data['assignments'] ?? [];
      return data
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      AppLogger.error(
        ErrorMessages.fetchAssignmentsFailed,
        e.response?.data ?? e.message,
        null,
        'CourseRepository',
      );
      throw Exception(ErrorMessages.fetchAssignmentsFailed);
    }
  }

  /// Ambil detail materi
  Future<CourseMaterialModel> fetchMaterialDetail(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.materialDetail(id));

      // PERBAIKAN: Mengutamakan key 'material' yang sekarang dikirim oleh Laravel
      final data = response.data;
      final materialJson = data['material'] ?? // <-- Ini yang utama sekarang
          data['post'] ??
          data['assignment'] ??
          data;

      if (materialJson == null) {
        throw Exception('Data materi tidak ditemukan dalam respons');
      }

      return CourseMaterialModel.fromJson(materialJson as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error(
        ErrorMessages.fetchMaterialDetailFailed,
        e.response?.data ?? e.message,
        null,
        'CourseRepository',
      );
      throw Exception(ErrorMessages.fetchMaterialDetailFailed);
    }
  }

  ///  Ambil detail tugas
  Future<AssignmentModel> fetchAssignmentDetail(int id) async {
    try {
      // gunakan endpoint khusus detail tugas /student/assignments/$id,
      // yang akan kembali menggunakan PostController@show dan key 'assignment'.
      final response = await _dio.get(ApiEndpoints.assignmentDetail(id));
      final assignmentJson = response.data['assignment'] ?? response.data;
      return AssignmentModel.fromJson(assignmentJson as Map<String, dynamic>);
    } on DioException catch (e) {
      AppLogger.error(
        ErrorMessages.fetchAssignmentDetailFailed,
        e.response?.data ?? e.message,
        null,
        'CourseRepository',
      );
      throw Exception(ErrorMessages.fetchAssignmentDetailFailed);
    }
  }
}

/// Provider untuk CourseRepository
final courseRepositoryProvider = Provider((ref) {
  final dio = ref.read(apiClientProvider);
  return CourseRepository(dio);
});
