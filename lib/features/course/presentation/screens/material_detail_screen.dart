import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/providers/course_providers.dart';
import '../../domain/models/course_material_model.dart';

/// ===============================================
/// FUNGSI UTILITAS: Membuka URL Eksternal
/// ===============================================
Future<void> _launchUrl(String url, BuildContext context) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gagal membuka $url. Pastikan tautan valid atau gunakan path lengkap dari server.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// ===============================================
/// WIDGET: TAUTAN EKSTERNAL
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => _launchUrl(url, context),
          icon: const Icon(Icons.link),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tautan Lengkap:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: () => _launchUrl(url, context),
          child: Text(
            url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade800,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

/// ===============================================
/// WIDGET: FILE ATTACHMENT
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
    String buttonText = 'Unduh File (${fileType.toUpperCase()})';
    IconData icon =
        fileType == 'pdf' ? Icons.picture_as_pdf : Icons.attach_file;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'File Lampiran:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: () => _launchUrl(path, context),
          icon: Icon(icon),
          label: Text(buttonText),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        )
      ],
    );
  }
}

/// ===============================================
/// WIDGET: EMBED VIDEO (HTML IFRAME)
/// Dengan dukungan fullscreen
/// ===============================================
class VideoEmbedWidget extends StatefulWidget {
  final String embedCode;

  const VideoEmbedWidget({super.key, required this.embedCode});

  @override
  State<VideoEmbedWidget> createState() => _VideoEmbedWidgetState();
}

class _VideoEmbedWidgetState extends State<VideoEmbedWidget> {
  late final WebViewController _controller;
  String? _videoUrl;
  bool _isLoading = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _extractVideoUrl();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (_) {},
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      );

    if (_videoUrl != null && Uri.tryParse(_videoUrl!)?.hasAbsolutePath == true) {
      _controller.loadRequest(Uri.parse(_videoUrl!));
    }
  }

  @override
  void didUpdateWidget(VideoEmbedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.embedCode != oldWidget.embedCode) {
      _extractVideoUrl();
      if (_videoUrl != null) {
        _controller.loadRequest(Uri.parse(_videoUrl!));
      }
    }
  }

  void _extractVideoUrl() {
    final RegExp srcRegex = RegExp("src=[\"']?([^\"'>]+)[\"']?");
    final match = srcRegex.firstMatch(widget.embedCode);
    if (match != null) {
      _videoUrl = match.group(1);
    } else {
      final isUrl = Uri.tryParse(widget.embedCode)?.hasAbsolutePath ?? false;
      if (isUrl) _videoUrl = widget.embedCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoUrl == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          'Format embed video tidak valid atau URL tidak ditemukan.',
          style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Konten Video:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Kontainer video dengan tombol fullscreen
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: WebViewWidget(controller: _controller),
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),

              // Tombol fullscreen di pojok kanan bawah
              Positioned(
                right: 8,
                bottom: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: () {
                    setState(() => _isFullscreen = true);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FullscreenVideoPage(videoUrl: _videoUrl!),
                      ),
                    ).then((_) => setState(() => _isFullscreen = false));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===============================================
/// HALAMAN FULLSCREEN VIDEO
/// ===============================================
class FullscreenVideoPage extends StatefulWidget {
  final String videoUrl;
  const FullscreenVideoPage({super.key, required this.videoUrl});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.videoUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: WebViewWidget(controller: _controller)),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================
/// SCREEN: DETAIL MATERI
/// ===============================================
class MaterialDetailScreen extends ConsumerWidget {
  final int materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  void _addDivider(List<Widget> list, {required bool needsDivider}) {
    if (needsDivider) {
      list.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialAsync = ref.watch(materialDetailProvider(materialId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Materi')),
      body: materialAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('❌ Gagal memuat detail materi.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Error: $error', style: const TextStyle(fontStyle: FontStyle.italic)), // Pesan error Dio/Parsing
                // Tambahkan ini untuk melihat stack trace (Penting untuk debugging)
                // Text('Stack: $stack', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
        data: (item) {
          List<Widget> dynamicContent = [];
          bool needsDivider = false;

          if ((item.link ?? '').isNotEmpty) {
            _addDivider(dynamicContent, needsDivider: needsDivider);
            dynamicContent.add(
              ExternalLinkWidget(url: item.link!, label: 'Buka Tautan Eksternal'),
            );
            needsDivider = true;
          }

          if (item.attachment?.isNotEmpty == true) {
            _addDivider(dynamicContent, needsDivider: needsDivider);
            dynamicContent.add(
              AttachmentFileWidget(
                path: item.attachment!,
                fileType: (item.attachment!.split('.').last).toLowerCase(),
              ),
            );
            needsDivider = true;
          }

          if (item.embed?.isNotEmpty == true) {
            _addDivider(dynamicContent, needsDivider: needsDivider);
            dynamicContent.add(VideoEmbedWidget(embedCode: item.embed!));
            needsDivider = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title ?? 'Tidak ada judul tersedia.',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (item.subjectName.isNotEmpty)
                  Text(
                    item.subjectName,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade600),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.folder, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Tipe: ${item.fileType}',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const Divider(height: 30),
                ...dynamicContent,
                if (dynamicContent.isNotEmpty) const SizedBox(height: 24),
                const Text(
                  'Deskripsi Materi:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description ?? 'Tidak ada deskripsi rinci tersedia.',
                  style: TextStyle(fontSize: 16, fontStyle: item.description == null
                      ? FontStyle.italic
                      : FontStyle.normal),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
