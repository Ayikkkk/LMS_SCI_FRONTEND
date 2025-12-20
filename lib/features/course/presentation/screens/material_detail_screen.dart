import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/course_material_model.dart';
import '../../domain/providers/course_providers.dart';

/// =================================================
/// BACKEND CONFIG (REAL SETUP)
/// =================================================
/// API   : http://192.168.1.10:8000/api/
/// FILE  : http://192.168.1.10:8000/storage/
/// =================================================

String resolveFileUrl(String path) {
  if (path.startsWith('http')) return path;
  return '$apiHost/storage/${path.replaceAll(RegExp(r'^/+'), '')}';
}

/// ===============================================
/// UTIL: OPEN URL VIA SYSTEM (ANDROID STABLE)
/// NOTE:
/// - TANPA canLaunchUrl (BUGGY DI MIUI)
/// - LANGSUNG launchUrl + try-catch
/// ===============================================
Future<void> _launchExternalUrl(String url, BuildContext context) async {
  try {
    final uri = Uri.parse(url.trim());

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka file'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// ===============================================
/// WIDGET: EXTERNAL LINK
/// ===============================================
class ExternalLinkWidget extends StatelessWidget {
  final String url;
  final String label;

  const ExternalLinkWidget({
    super.key,
    required this.url,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.link),
      label: Text(label),
      onPressed: () => _launchExternalUrl(url, context),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

/// ===============================================
/// WIDGET: FILE ATTACHMENT
/// Download via Chrome / Download Manager
/// ===============================================
class AttachmentFileWidget extends StatelessWidget {
  final String path;
  final String fileType;

  const AttachmentFileWidget({
    super.key,
    required this.path,
    required this.fileType,
  });

  @override
  Widget build(BuildContext context) {
    final icon = fileType == 'pdf' ? Icons.picture_as_pdf : Icons.attach_file;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Lampiran:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: Icon(icon),
          label: Text('Unduh File (${fileType.toUpperCase()})'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () async {
            final url = resolveFileUrl(path);
            await _launchExternalUrl(url, context);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'File sedang diunduh. Cek folder Download.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

/// ===============================================
/// WIDGET: VIDEO EMBED
/// ===============================================
class VideoEmbedWidget extends StatefulWidget {
  final String embedCode;

  const VideoEmbedWidget({super.key, required this.embedCode});

  @override
  State<VideoEmbedWidget> createState() => _VideoEmbedWidgetState();
}

class _VideoEmbedWidgetState extends State<VideoEmbedWidget> {
  late final WebViewController _controller;
  String? _url;

  @override
  void initState() {
    super.initState();

    final regex = RegExp('src=["\']([^"\']+)["\']');
    final match = regex.firstMatch(widget.embedCode);

    _url = match?.group(1) ??
        (Uri.tryParse(widget.embedCode)?.hasAbsolutePath == true
            ? widget.embedCode
            : null);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    if (_url != null) {
      _controller.loadRequest(Uri.parse(_url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return const Text(
        'Embed video tidak valid',
        style: TextStyle(color: Colors.red),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: _controller),
    );
  }
}

/// ===============================================
/// SCREEN: MATERIAL DETAIL
/// ===============================================
class MaterialDetailScreen extends ConsumerWidget {
  final int materialId;

  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMaterial = ref.watch(materialDetailProvider(materialId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Materi')),
      body: asyncMaterial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (CourseMaterialModel item) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.subjectName,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Divider(height: 32),
                if (item.link?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),

                  // ====== JUDUL LINK ======
                  const Text(
                    'Link Materi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ExternalLinkWidget(
                    url: item.link!,
                    label: 'Buka Tautan',
                  ),
                ],
                if (item.attachment?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  AttachmentFileWidget(
                    path: item.attachment!,
                    fileType: item.attachment!.split('.').last.toLowerCase(),
                  ),
                ],
                if (item.embed?.isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  // ====== JUDUL KONTEN VIDEO ======
                  const Text(
                    'Konten Materi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  VideoEmbedWidget(embedCode: item.embed!),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Deskripsi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(item.description ?? '-'),
              ],
            ),
          );
        },
      ),
    );
  }
}
