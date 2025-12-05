import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'dart:convert';

class LaporanRepository {
  final Dio _dio;
  final AuthRepository _auth;

  LaporanRepository(this._dio, this._auth);

  /// Ambil semua laporan user
  Future<List<dynamic>> getReports() async {
    try {
      final token = await _auth.getToken();

      final res = await _dio.get(
        "/student/reports",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return res.data["data"] ?? [];
    } catch (e) {
      rethrow; // biar provider menangkap error
    }
  }

  /// Cek apakah user sudah mengisi laporan hari ini
  Future<bool> isFilledToday() async {
    final list = await getReports();

    final today = DateTime.now();

    for (var r in list) {
      final t = DateTime.parse(r["created_at"]);

      if (t.year == today.year &&
          t.month == today.month &&
          t.day == today.day) {
        return true;
      }
    }

    return false;
  }

  /// Kirim laporan harian
  Future<void> submitReport({
    required List<String> report,
    required MultipartFile? img,
  }) async {
    try {
      final token = await _auth.getToken();

      final form = FormData.fromMap({
        "report": jsonEncode(report), // backend kamu pakai string JSON
        if (img != null) "img": img,
      });

      await _dio.post(
        "/student/reports",
        data: form,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider repository
final laporanRepositoryProvider = Provider((ref) {
  final auth = ref.read(authRepositoryProvider);
  return LaporanRepository(dio, auth);
});
