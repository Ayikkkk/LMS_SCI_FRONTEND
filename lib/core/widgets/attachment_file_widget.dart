import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class AttachmentFileWidget extends ConsumerStatefulWidget {
  final int postId;
  final String fileName;
  final String fileType;
  final String? downloadUrl;
  final String? label;

  const AttachmentFileWidget({
    super.key,
    required this.postId,
    required this.fileName,
    required this.fileType,
    this.downloadUrl,
    this.label,
  });

  @override
  ConsumerState<AttachmentFileWidget> createState() =>
      _AttachmentFileWidgetState();
}

class _AttachmentFileWidgetState extends ConsumerState<AttachmentFileWidget> {
  bool _isDownloading = false;
  bool _isDone = false;

  String get _effectiveUrl =>
      widget.downloadUrl ?? '/student/posts/${widget.postId}/download';

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Mengunduh file...')),
    );

    try {
      // Simpan ke temp dulu
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${widget.fileName}';

      // Pilih Dio instance — URL guru domain pakai Dio baru (tanpa auth header)
      final isExternalUrl = _effectiveUrl.startsWith('http://') ||
          _effectiveUrl.startsWith('https://');
      final dioToUse = isExternalUrl
          ? Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 60),
            ))
          : ref.read(apiClientProvider);

      final response = await dioToUse.download(
        _effectiveUrl,
        tempPath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 600,
          headers: isExternalUrl ? {'Accept': '*/*'} : null,
        ),
      );

      if (response.statusCode != 200) {
        String message = 'File tidak dapat diunduh (${response.statusCode})';
        throw Exception(message);
      }

      final tempFile = File(tempPath);
      if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
        throw Exception('File kosong setelah download');
      }

      // Simpan ke folder Download via MediaStore
      MediaStore.appFolder = AppConstants.mediaStoreFolder;
      await MediaStore.ensureInitialized();

      final store = MediaStore();
      await store.saveFile(
        tempFilePath: tempPath,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      // Hapus temp file jika masih ada (MediaStore mungkin sudah memindahkannya)
      try {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      } catch (_) {
        // Abaikan error hapus temp — file sudah di Download
      }

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _isDone = true;
      });

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ ${widget.fileName} tersimpan di folder Download/LMS Student'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      AppLogger.error(
          'Download attachment failed', e, null, 'AttachmentFileWidget');

      if (!mounted) return;
      setState(() => _isDownloading = false);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _isDownloading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(_isDone ? Icons.check_circle_outline : Icons.download),
      label: Text(
        _isDone
            ? 'Tersimpan di Download/LMS Student'
            : (widget.label ?? 'Unduh File (${widget.fileType.toUpperCase()})'),
      ),
      style: _isDone
          ? ElevatedButton.styleFrom(backgroundColor: Colors.green)
          : null,
      onPressed: _isDownloading ? null : _download,
    );
  }
}
