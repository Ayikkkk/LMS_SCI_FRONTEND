// lib/features/course/presentation/screens/material_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/widgets/attachment_file_widget.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../data/models/course_material_model.dart';
import '../../domain/providers/comment_provider.dart';
import '../../domain/providers/course_providers.dart';
import '../../presentation/widgets/add_comment_field.dart';
import '../../presentation/widgets/comment_list_widget.dart';

class MaterialDetailScreen extends ConsumerStatefulWidget {
  final int materialId;
  const MaterialDetailScreen({super.key, required this.materialId});

  @override
  ConsumerState<MaterialDetailScreen> createState() =>
      _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen> {
  int? replyToCommentId;
  int? editingCommentId;
  int? editingReplyId;
  String? editingInitialText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.materialId);
    });
  }

  void _cancelAction() => setState(() {
        replyToCommentId = null;
        editingCommentId = null;
        editingReplyId = null;
        editingInitialText = null;
      });

  @override
  Widget build(BuildContext context) {
    final asyncMaterial = ref.watch(materialDetailProvider(widget.materialId));
    final student = ref.watch(studentProvider);

    return asyncMaterial.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Detail Materi')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (CourseMaterialModel item) => Scaffold(
        appBar: AppBar(
          title: const Text('Detail Materi'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────
                    _HeaderSection(item: item),
                    const SizedBox(height: 16),

                    // ── Konten ──────────────────────────────
                    if (item.embed?.isNotEmpty == true) ...[
                      _SectionLabel('Video'),
                      const SizedBox(height: 8),
                      _VideoEmbedWidget(embedCode: item.embed!),
                      const SizedBox(height: 16),
                    ],

                    if (item.link?.isNotEmpty == true) ...[
                      _SectionLabel('Tautan'),
                      const SizedBox(height: 8),
                      _LinkButton(url: item.link!),
                      const SizedBox(height: 16),
                    ],

                    if (item.attachment?.isNotEmpty == true) ...[
                      _SectionLabel('Lampiran'),
                      const SizedBox(height: 8),
                      AttachmentFileWidget(
                        postId: item.id,
                        fileName: item.attachment!.split('/').last,
                        fileType: item.attachment!.split('.').last,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (item.description?.isNotEmpty == true) ...[
                      _SectionLabel('Deskripsi'),
                      const SizedBox(height: 6),
                      Text(item.description!,
                          style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 16),
                    ],

                    // ── Komentar ─────────────────────────────
                    _SectionLabel('Komentar'),
                    const SizedBox(height: 8),
                    student == null
                        ? const Center(child: CircularProgressIndicator())
                        : CommentListWidget(
                            postId: item.id,
                            currentUser: student,
                            onReplySelected: (id) => setState(() {
                              replyToCommentId = id;
                              editingCommentId = null;
                              editingReplyId = null;
                              editingInitialText = null;
                            }),
                            onEditSelected: (id, msg) => setState(() {
                              editingCommentId = id;
                              editingInitialText = msg;
                              replyToCommentId = null;
                              editingReplyId = null;
                            }),
                            onEditReplySelected: (rId, msg, pId) =>
                                setState(() {
                              editingReplyId = rId;
                              replyToCommentId = pId;
                              editingInitialText = msg;
                              editingCommentId = null;
                            }),
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // ── Input komentar ───────────────────────────────
            if (student != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, -2))
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: AddCommentField(
                    postId: item.id,
                    commentId:
                        editingReplyId ?? editingCommentId ?? replyToCommentId,
                    parentCommentId:
                        editingReplyId != null ? replyToCommentId : null,
                    isEditing:
                        editingCommentId != null || editingReplyId != null,
                    isReply: editingReplyId != null,
                    initialText: editingInitialText,
                    onCancelAction: _cancelAction,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final CourseMaterialModel item;
  const _HeaderSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.subjectName,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String url;
  const _LinkButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(
        url.length > 50 ? '${url.substring(0, 50)}...' : url,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        alignment: Alignment.centerLeft,
      ),
      onPressed: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak dapat membuka tautan')),
            );
          }
        }
      },
    );
  }
}

class _VideoEmbedWidget extends StatefulWidget {
  final String embedCode;
  const _VideoEmbedWidget({required this.embedCode});

  @override
  State<_VideoEmbedWidget> createState() => _VideoEmbedWidgetState();
}

class _VideoEmbedWidgetState extends State<_VideoEmbedWidget> {
  late final WebViewController _controller;
  String? _url;

  @override
  void initState() {
    super.initState();
    final regex = RegExp('src=["\']([^"\']+)["\']');
    _url = regex.firstMatch(widget.embedCode)?.group(1);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    if (_url != null) _controller.loadRequest(Uri.parse(_url!));
  }

  @override
  Widget build(BuildContext context) {
    if (_url == null) {
      return const Text('Embed tidak valid',
          style: TextStyle(color: Colors.red));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
