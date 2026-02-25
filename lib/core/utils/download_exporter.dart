import 'dart:io';
import 'package:media_store_plus/media_store_plus.dart';

import '../constants/app_constants.dart';
import 'logger.dart';

class DownloadExporter {
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;

    MediaStore.appFolder = AppConstants.mediaStoreFolder;
    await MediaStore.ensureInitialized();

    _initialized = true;
    AppLogger.success('MediaStore initialized', 'DownloadExporter');
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

      AppLogger.success('File copied to Download folder', 'DownloadExporter');
      return true;
    } catch (e) {
      AppLogger.error('Copy to download failed', e, null, 'DownloadExporter');
      return false;
    }
  }
}

