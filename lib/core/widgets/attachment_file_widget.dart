import 'dart:io';
import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../utils/file_downloader.dart';
import '../utils/download_exporter.dart';

class AttachmentFileWidget extends StatefulWidget {
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
  State<AttachmentFileWidget> createState() => _AttachmentFileWidgetState();
}

class _AttachmentFileWidgetState extends State<AttachmentFileWidget> {
  File? downloadedFile;
  bool isDownloading = false;

  // ==========================
  // DOWNLOAD FILE (TANPA OPEN)
  // ==========================
  Future<void> _download(BuildContext context) async {
    if (isDownloading) return;

    setState(() => isDownloading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengunduh file...')),
    );

    final file = await FileDownloader.download(
      dio: dio,
      url: widget.downloadUrl ?? '/student/posts/${widget.postId}/download',
      fileName: widget.fileName,
    );

    if (!mounted) return;

    setState(() {
      isDownloading = false;
      downloadedFile = file;
    });

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengunduh file')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File berhasil diunduh')),
      );
    }
  }

  // ==========================
  // COPY TO DOWNLOAD
  // ==========================
  Future<void> _copyToDownload(BuildContext context) async {
    if (downloadedFile == null) return;

    final success = await DownloadExporter.copyToDownload(downloadedFile!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'File disalin ke Folder Download/LMS Student'
              : 'Gagal menyalin ke Folder Download',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================
        // DOWNLOAD BUTTON
        // ==========================
        ElevatedButton.icon(
          icon: isDownloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download),
          label: Text(
            widget.label ?? 'Unduh File (${widget.fileType.toUpperCase()})',
          ),
          onPressed: isDownloading ? null : () => _download(context),
        ),

        // ==========================
        // COPY TO DOWNLOAD BUTTON
        // ==========================
        if (downloadedFile != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_copy),
            label: const Text('Salin ke Folder Download'),
            onPressed: () => _copyToDownload(context),
          ),
        ],
      ],
    );
  }
}
