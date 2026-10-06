import 'dart:io';

import 'package:dio/dio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
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
  /// Simpan langsung ke folder Download via MediaStore
  /// Return path file di Download agar bisa dibuka
  /// ============================
  Future<String?> downloadRecapPdf() async {
    try {
      // 1. Download ke temp file dulu
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/rekap_nilai_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final response = await _dio.download(
        '/student/grades/rekap-mapel/pdf',
        tempPath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final tempFile = File(tempPath);
      if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
        throw Exception('File PDF kosong');
      }

      // 2. Simpan copy ke app documents untuk OpenFilex (sebelum MediaStore memindahkan)
      final docsDir = await getApplicationDocumentsDirectory();
      final docPath = '${docsDir.path}/rekap_nilai.pdf';
      await tempFile.copy(docPath);

      // 3. Simpan ke folder Download via MediaStore
      MediaStore.appFolder = AppConstants.mediaStoreFolder;
      await MediaStore.ensureInitialized();

      final store = MediaStore();
      await store.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      // 4. Hapus temp file jika masih ada
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}

      return docPath; // path untuk OpenFilex
    } catch (e) {
      rethrow; // lempar error agar bisa ditampilkan ke user
    }
  }
}
