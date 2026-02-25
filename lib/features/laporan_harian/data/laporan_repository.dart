import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/constants/error_messages.dart';
import '../../../core/utils/logger.dart';
import '../../auth/data/repository/auth_repository.dart';

class LaporanRepository {
  final Dio _dio;
  final AuthRepository _auth;

  LaporanRepository(this._dio, this._auth);

  // ======================================================
  // Ambil semua laporan user
  // ======================================================
  Future<List<dynamic>> getReports() async {
    try {
      final token = await _auth.getToken();

      final res = await _dio.get(
        "/student/reports",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return res.data["data"] ?? [];
    } catch (e) {
      AppLogger.error(ErrorMessages.fetchLaporanFailed, e, null, 'LaporanRepository');
      rethrow;
    }
  }

  // ======================================================
  // Cek laporan harian dengan endpoint check/today
  // ======================================================
  Future<bool> checkToday() async {
    try {
      final token = await _auth.getToken();

      final res = await _dio.get(
        "/student/reports/check/today",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return res.data["filled"] ?? false;
    } catch (e) {
      AppLogger.error('Check laporan error', e, null, 'LaporanRepository');
      return false;
    }
  }

  // Alias agar tetap kompatibel
  Future<bool> isFilledToday() async => checkToday();

  // ======================================================
  // Perbaikan submit laporan harian (FIX UPLOAD GAMBAR)
  // ======================================================
  Future<void> submitReport({
    required List<String> report,
    required MultipartFile? img,
  }) async {
    try {
      final token = await _auth.getToken();

      // FORMAT Multipart sesuai Laravel
      final form = FormData();

      // JSON laporan
      form.fields.add(MapEntry("report", jsonEncode(report)));

      // File gambar (FIX MIME TYPE)
      if (img != null) {
        form.files.add(
          MapEntry("img", img),
        );
      }

      await _dio.post(
        "/student/reports",
        data: form,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
          contentType: "multipart/form-data",
        ),
      );

      AppLogger.success('Laporan submitted successfully', 'LaporanRepository');
    } catch (e) {
      AppLogger.error(ErrorMessages.submitLaporanFailed, e, null, 'LaporanRepository');
      rethrow;
    }
  }
}

// Provider repository
final laporanRepositoryProvider = Provider((ref) {
  final dio = ref.read(apiClientProvider);
  final auth = ref.read(authRepositoryProvider);
  return LaporanRepository(dio, auth);
});
