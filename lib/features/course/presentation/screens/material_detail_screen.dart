import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/attachment_file_widget.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/video_embed_widget.dart';
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

class _MaterialDetailScreenState extends ConsumerState<MaterialDetailScreen>
    with WidgetsBindingObserver {
  int? replyToCommentId;
  int? editingCommentId;
  int? editingReplyId;
  String? editingInitialText;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.materialId);
    });
    // Auto-refresh setiap 60 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) ref.invalidate(materialDetailProvider(widget.materialId));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Refresh saat app kembali ke foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(materialDetailProvider(widget.materialId));
    }
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
        body: AppErrorWidget(
          message: ErrorMessages.fromException(e),
          onRetry: () =>
              ref.invalidate(materialDetailProvider(widget.materialId)),
        ),
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
                      VideoEmbedWidget(embedCode: item.embed!),
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
                        // Download langsung dari domain guru jika path mengandung subfolder
                        // (file diupload oleh guru, bukan dari backend siswa)
                        downloadUrl: item.attachment!.contains('/')
                            ? 'http://guru.tak-scimediaonline.my.id/storage/${Uri.encodeFull(item.attachment!)}'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (item.description?.isNotEmpty == true) ...[
                      _SectionLabel('Deskripsi'),
                      const SizedBox(height: 6),
                      Html(
                        data: item.description!,
                        style: {
                          'body': Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(15),
                            lineHeight: LineHeight(1.6),
                          ),
                          'h3': Style(
                            fontSize: FontSize(16),
                            fontWeight: FontWeight.bold,
                            margin: Margins.only(top: 12, bottom: 4),
                          ),
                          'p': Style(
                            margin: Margins.only(bottom: 8),
                          ),
                          'ul': Style(
                            margin: Margins.only(left: 16, bottom: 8),
                          ),
                          'ol': Style(
                            margin: Margins.only(left: 16, bottom: 8),
                          ),
                          'li': Style(
                            margin: Margins.only(bottom: 4),
                          ),
                        },
                      ),
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
