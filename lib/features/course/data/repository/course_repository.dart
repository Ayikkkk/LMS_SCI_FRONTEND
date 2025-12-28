// course_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_frontend/core/network/api_client.dart';
import '../models/assignment_model.dart';
import '../models/course_material_model.dart';

class CourseRepository {
  final Dio _dio;
  CourseRepository(this._dio);

  /// 📘 Ambil daftar materi siswa
  Future<List<CourseMaterialModel>> fetchMaterials() async {
    try {
      final response = await _dio.get('/student/materials');
      final List<dynamic> data = response.data['materials'] ?? [];
      return data
          .map((e) => CourseMaterialModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Error fetching materials: ${e.response?.data ?? e.message}');
      throw Exception('Gagal memuat materi');
    }
  }

  /// 📄 Ambil daftar tugas siswa
  Future<List<AssignmentModel>> fetchAssignments() async {
    try {
      final response = await _dio.get('/student/assignments');
      final List<dynamic> data = response.data['assignments'] ?? [];
      return data
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('Error fetching assignments: ${e.response?.data ?? e.message}');
      throw Exception('Gagal memuat daftar tugas');
    }
  }

  /// 📘 Ambil detail materi
  Future<CourseMaterialModel> fetchMaterialDetail(int id) async {
    try {
      final response = await _dio.get('/student/posts/$id');

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
      print('Error fetching material detail: ${e.response?.data ?? e.message}');
      throw Exception('Gagal memuat detail materi');
    }
  }

  /// 📄 Ambil detail tugas
  Future<AssignmentModel> fetchAssignmentDetail(int id) async {
    try {
      // gunakan endpoint khusus detail tugas /student/assignments/$id,
      // yang akan kembali menggunakan PostController@show dan key 'assignment'.
      final response = await _dio.get('/student/assignments/$id');
      final assignmentJson = response.data['assignment'] ?? response.data;
      return AssignmentModel.fromJson(assignmentJson as Map<String, dynamic>);
    } on DioException catch (e) {
      print(
          'Error fetching assignment detail: ${e.response?.data ?? e.message}');
      throw Exception('Gagal memuat detail tugas');
    }
  }
}

/// Provider untuk CourseRepository
final courseRepositoryProvider = Provider((ref) => CourseRepository(dio));