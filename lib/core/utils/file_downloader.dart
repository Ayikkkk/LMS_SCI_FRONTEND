import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class FileDownloader {
  FileDownloader._();

  static Future<File?> download({
    required Dio dio,
    required String url,
    required String fileName,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      debugPrint('⬇️ DOWNLOAD START');
      debugPrint('URL      : $url');
      debugPrint('SAVE TO  : $filePath');

      final response = await dio.download(url, filePath);

      if (response.statusCode != 200) return null;

      final file = File(filePath);
      if (!file.existsSync()) return null;

      debugPrint('📂 FILE SAVED: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('❌ DOWNLOAD ERROR: $e');
      return null;
    }
  }
}

