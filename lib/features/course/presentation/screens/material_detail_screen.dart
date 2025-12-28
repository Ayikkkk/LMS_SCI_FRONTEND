// lib/features/course/presentation/screens/material_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/course_material_model.dart';
import '../../domain/providers/course_providers.dart';

// KOMENTAR
import '../../domain/providers/comment_provider.dart';
import '../../presentation/widgets/comment_list_widget.dart';
import '../../presentation/widgets/add_comment_field.dart';

// DATA SISWA LOGIN
import '../../../profile/presentation/providers/profile_provider.dart';

String resolveFileUrl(String path) {
  if (path.startsWith('http')) return path;
  return '$apiHost/storage/${path.replaceAll(RegExp(r'^/+'), '')}';
}

Future<void> _launchExternalUrl(String url, BuildContext context) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka file')),
      );
    }
  }
}

class ExternalLinkWidget extends StatelessWidget {
  final String url;
  final String label;

  const ExternalLinkWidget({super.key, required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.link),
      label: Text(label),
      onPressed: () => _launchExternalUrl(url, context),
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
    );
  }
}

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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Lampiran:", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.attach_file),
        label: Text("Unduh File (${fileType.toUpperCase()})"),
        onPressed: () => _launchExternalUrl(resolveFileUrl(path), context),
      ),
    ]);
  }
}

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
    _url = regex.firstMatch(widget.embedCode)?.group(1);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    if (_url != null) {
      _controller.loadRequest(Uri.parse(_url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return const Text('Embed tidak valid', style: TextStyle(color: Colors.red));
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: _controller),
    );
  }
}

// ====================================
// 🔥 MAIN SCREEN MATERIAL DETAIL
// ====================================
class MaterialDetailScreen extends ConsumerStatefulWidget {
  final int materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  int? replyToCommentId; // Track mode reply

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.materialId);
    });
  }

  // ⬇️ saat klik tombol "Balas"
  void startReply(int commentId) {
    setState(() {
      replyToCommentId = commentId;
    });
  }

  // ⬇️ saat klik tombol batal reply
  void cancelReply() {
    setState(() {
      replyToCommentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncMaterial =
        ref.watch(materialDetailProvider(widget.materialId));
    final student = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Materi')),
      body: asyncMaterial.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (CourseMaterialModel item) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(item.subjectName, style: TextStyle(color: Colors.grey.shade600)),
                    const Divider(),

                    if (item.link?.isNotEmpty == true)
                      ExternalLinkWidget(url: item.link!, label: "Buka Tautan"),

                    if (item.attachment?.isNotEmpty == true)
                      AttachmentFileWidget(
                          path: item.attachment!,
                          fileType: item.attachment!.split('.').last),

                    if (item.embed?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      VideoEmbedWidget(embedCode: item.embed!),
                    ],

                    const SizedBox(height: 20),
                    const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(item.description ?? "-"),

                    const SizedBox(height: 30),
                    const Text("Komentar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),

                    if (student == null)
                      const Center(child: CircularProgressIndicator())
                    else
                      CommentListWidget(
                        postId: item.id,
                        currentUser: student,
                        onReplySelected: startReply, // ⬅️ penting!
                      ),
                  ]),
                ),
              ),

              // ============================
              // INPUT KOMENTAR / BALAS
              // ============================
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, -3),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: AddCommentField(
                    postId: item.id,
                    commentId: replyToCommentId,
                    onCancelReply: cancelReply,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
