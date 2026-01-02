import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';

class DownloadExporter {
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;

    MediaStore.appFolder = "LMS Student";
    await MediaStore.ensureInitialized();

    _initialized = true;
  }

  static Future<bool> copyToDownload(File file) async {
    try {
      await _init();

      final store = MediaStore();
      await store.saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      return true;
    } catch (e) {
      debugPrint('❌ COPY TO DOWNLOAD FAILED: $e');
      return false;
    }
  }
}

