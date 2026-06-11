import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Path file di app documents (untuk dibuka dengan OpenFilex)
  String? _localFilePath;

  /// Key SharedPreferences untuk menyimpan path file ini
  String get _prefKey => 'attachment_path_${widget.postId}_${widget.fileName}';

  String get _effectiveUrl =>
      widget.downloadUrl ?? '/student/posts/${widget.postId}/download';

  @override
  void initState() {
    super.initState();
    _loadSavedPath();
  }

  /// Cek apakah file sudah pernah didownload dan masih ada
  Future<void> _loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && File(saved).existsSync()) {
      if (mounted) setState(() => _localFilePath = saved);
    } else if (saved != null) {
      // File sudah tidak ada (misal terhapus user), bersihkan cache
      await prefs.remove(_prefKey);
    }
  }

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Mengunduh file...')),
    );

    try {
      // 1. Download ke temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${widget.fileName}';

      // Pilih Dio instance — URL eksternal pakai Dio baru (tanpa auth header)
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
        throw Exception('File tidak dapat diunduh (${response.statusCode})');
      }

      final tempFile = File(tempPath);
      if (!tempFile.existsSync() || tempFile.lengthSync() == 0) {
        throw Exception('File kosong setelah download');
      }

      // 2. Simpan copy ke app documents (agar bisa dibuka OpenFilex)
      final docsDir = await getApplicationDocumentsDirectory();
      final docPath = '${docsDir.path}/${widget.fileName}';
      await tempFile.copy(docPath);

      // 3. Simpan ke folder Download via MediaStore (untuk akses dari file manager)
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

      // 5. Simpan path ke SharedPreferences agar persisten
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, docPath);

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _localFilePath = docPath;
      });

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              '✅ ${widget.fileName} tersimpan di folder Download/LMS Student'),
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

  Future<void> _openFile() async {
    if (_localFilePath == null) return;

    // Cek file masih ada
    if (!File(_localFilePath!).existsSync()) {
      // File terhapus, reset state dan minta download ulang
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      if (mounted) setState(() => _localFilePath = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File tidak ditemukan, silakan unduh ulang'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await OpenFilex.open(_localFilePath!);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka file: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDownloaded = _localFilePath != null;

    if (isDownloaded) {
      // Tampilkan dua tombol: Buka File + Download Ulang
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text(
              'Buka File (${widget.fileType.toUpperCase()})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: _openFile,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Unduh Ulang', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: EdgeInsets.zero,
            ),
            onPressed: _isDownloading ? null : _download,
          ),
        ],
      );
    }

    // Belum didownload
    return ElevatedButton.icon(
      icon: _isDownloading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.download),
      label: Text(
        _isDownloading
            ? 'Mengunduh...'
            : (widget.label ?? 'Unduh File (${widget.fileType.toUpperCase()})'),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: _isDownloading ? null : _download,
    );
  }
}
