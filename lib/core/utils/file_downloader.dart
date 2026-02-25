import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'logger.dart';

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

      AppLogger.download('Starting download: $fileName');
      AppLogger.debug('URL: $url', 'FileDownloader');
      AppLogger.debug('Save to: $filePath', 'FileDownloader');

      final response = await dio.download(url, filePath);

      if (response.statusCode != 200) {
        AppLogger.error('Download failed with status: ${response.statusCode}', null, null, 'FileDownloader');
        return null;
      }

      final file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.error('File does not exist after download', null, null, 'FileDownloader');
        return null;
      }

      AppLogger.success('File saved: ${file.path}', 'FileDownloader');
      return file;
    } catch (e) {
      AppLogger.error('Download error', e, null, 'FileDownloader');
      return null;
    }
  }
}

