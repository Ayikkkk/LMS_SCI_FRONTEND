import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_store_plus/media_store_plus.dart';

class DownloadExporter {
  static bool _initialized = false;

  static Future<void> _initMediaStore() async {
    if (_initialized) return;

    // 🔥 WAJIB SET APP FOLDER
    MediaStore.appFolder = "LMS Student";

    await MediaStore.ensureInitialized();
    _initialized = true;

    debugPrint('✅ MediaStore initialized');
  }

  static Future<bool> copyToDownload(File file) async {
    try {
      await _initMediaStore();

      final mediaStore = MediaStore();

      await mediaStore.saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      debugPrint('✅ FILE COPIED TO DOWNLOAD');
      return true;
    } catch (e) {
      debugPrint('❌ COPY TO DOWNLOAD FAILED: $e');
      return false;
    }
  }
}
