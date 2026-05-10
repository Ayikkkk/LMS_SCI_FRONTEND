// lib/features/course/presentation/screens/assignment_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/attachment_file_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/video_embed_widget.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../data/models/assignment_model.dart';
import '../../domain/providers/comment_provider.dart';
import '../../domain/providers/course_providers.dart';
import '../../presentation/widgets/add_comment_field.dart';
import '../../presentation/widgets/comment_list_widget.dart';
import '../screens/submit_task_screen.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final int assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen>
    with WidgetsBindingObserver {
  int? replyToCommentId;
  int? editingCommentId;
  int? editingReplyId;
  String? editingInitialText;
  Timer? _refreshTimer;

  int? _parsePoint(dynamic point) {
    if (point == null || point.toString().isEmpty) return null;
    return int.tryParse(point.toString());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted)
        ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.assignmentId);
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
      ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    }
  }

  void _refreshAssignment() {
    ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    ref.invalidate(dashboardAssignmentsProvider);
  }

  void _cancelAction() => setState(() {
        replyToCommentId = null;
        editingCommentId = null;
        editingReplyId = null;
        editingInitialText = null;
      });

  @override
  Widget build(BuildContext context) {
    final asyncAssignment =
        ref.watch(assignmentDetailProvider(widget.assignmentId));
    final student = ref.watch(studentProvider);

    // Listen for changes to refresh dashboard
    ref.listen(assignmentDetailProvider(widget.assignmentId), (_, next) {
      next.whenData((_) => ref.invalidate(dashboardAssignmentsProvider));
    });

    return asyncAssignment.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: AppErrorWidget(
          message: 'Gagal memuat detail tugas',
          onRetry: () =>
              ref.invalidate(assignmentDetailProvider(widget.assignmentId)),
        ),
      ),
      data: (assignment) {
        final score = _parsePoint(assignment.point);
        final canSubmit = !assignment.isSubmitted && !assignment.isLate;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Tugas'),
            centerTitle: true,
          ),
          // Tombol kumpulkan selalu terlihat di bawah
          bottomNavigationBar: canSubmit
              ? _SubmitBar(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmitTaskScreen(
                          assignmentId: assignment.id,
                          assignmentTitle: assignment.title,
                          isSubmitted: assignment.isSubmitted,
                        ),
                      ),
                    );
                    if (result == true) _refreshAssignment();
                  },
                )
              : null,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────
                      _HeaderSection(assignment: assignment),
                      const SizedBox(height: 16),

                      // ── Info card (tenggat, status, nilai) ──
                      _InfoCard(assignment: assignment, score: score),
                      const SizedBox(height: 16),

                      // ── Konten tugas ────────────────────────
                      if (assignment.description?.isNotEmpty == true) ...[
                        _SectionLabel('Deskripsi'),
                        const SizedBox(height: 6),
                        Text(assignment.description!,
                            style: const TextStyle(height: 1.5)),
                        const SizedBox(height: 16),
                      ],

                      if (assignment.embed?.isNotEmpty == true) ...[
                        _SectionLabel('Video'),
                        const SizedBox(height: 8),
                        VideoEmbedWidget(embedCode: assignment.embed!),
                        const SizedBox(height: 16),
                      ],

                      if (assignment.link?.isNotEmpty == true) ...[
                        _SectionLabel('Tautan'),
                        const SizedBox(height: 8),
                        _LinkButton(url: assignment.link!),
                        const SizedBox(height: 16),
                      ],

                      if (assignment.attachment?.isNotEmpty == true) ...[
                        _SectionLabel('Lampiran'),
                        const SizedBox(height: 8),
                        AttachmentFileWidget(
                          postId: assignment.id,
                          fileName: assignment.attachment!.split('/').last,
                          fileType: assignment.attachment!.split('.').last,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Status pengumpulan ───────────────────
                      if (assignment.isSubmitted)
                        _StatusBanner(
                          text: score != null
                              ? 'Tugas sudah dinilai ✔️'
                              : 'Menunggu penilaian guru ⏳',
                          color: score != null ? Colors.green : Colors.orange,
                        )
                      else if (assignment.isLate)
                        const _StatusBanner(
                          text: 'Batas waktu sudah terlewat ❌',
                          color: Colors.redAccent,
                        ),

                      const SizedBox(height: 24),

                      // ── Komentar ─────────────────────────────
                      _SectionLabel('Komentar'),
                      const SizedBox(height: 8),
                      student == null
                          ? const Center(child: CircularProgressIndicator())
                          : CommentListWidget(
                              postId: assignment.id,
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
                      postId: assignment.id,
                      commentId: editingReplyId ??
                          editingCommentId ??
                          replyToCommentId,
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
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final AssignmentModel assignment;
  const _HeaderSection({required this.assignment});

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
            assignment.subjectName,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          assignment.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final AssignmentModel assignment;
  final int? score;
  const _InfoCard({required this.assignment, required this.score});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tenggat',
            value: assignment.dueDate != null
                ? DateFormat('EEE, dd MMM yyyy • HH:mm', 'id_ID')
                    .format(assignment.dueDate!)
                : 'Tanpa batas waktu',
            valueColor: assignment.isLate ? Colors.redAccent : null,
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Status',
            value: assignment.status,
            valueColor: assignment.statusColor,
            bold: true,
          ),
          if (score != null) ...[
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.star_outline_rounded,
              label: 'Nilai',
              value: '$score',
              valueColor: Colors.blue,
              bold: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('$label  ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
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

class _StatusBanner extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
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

class _SubmitBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SubmitBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.upload_rounded),
          label: const Text(
            'Kumpulkan Tugas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
