import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../models/recap_score_model.dart';

class GradeRepository {
  final Dio _dio;

  GradeRepository(this._dio);

  /// ============================
  /// Ambil rekap nilai per mapel
  /// ============================
  Future<RecapScoreModel> fetchRecapPerMapel() async {
    final response = await _dio.get(
      '/student/grades/rekap-mapel',
    );

    final data = response.data;

    if (data == null || data['success'] != true) {
      throw Exception('Gagal memuat rekap nilai');
    }

    return RecapScoreModel.fromJson(data);
  }

  /// ============================
  /// Download PDF rekap nilai
  /// ============================
  Future<File?> downloadRecapPdf() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/rekap_nilai.pdf';

      await _dio.download(
        '/student/grades/rekap-mapel/pdf',
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final file = File(filePath);

      if (!file.existsSync()) return null;

      await OpenFilex.open(filePath);
      return file;
    } catch (e) {
      return null;
    }
  }
}
