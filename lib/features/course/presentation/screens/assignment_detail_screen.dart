// lib/features/course/presentation/screens/assignment_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';

import '../screens/submit_task_screen.dart';
import '../../presentation/screens/material_detail_screen.dart'
    show ExternalLinkWidget, AttachmentFileWidget, VideoEmbedWidget;

import '../../domain/providers/course_providers.dart';
import '../../data/models/assignment_model.dart';

// 🔹 komentar
import '../../domain/providers/comment_provider.dart';
import '../../presentation/widgets/comment_list_widget.dart';
import '../../presentation/widgets/add_comment_field.dart';

// 🔹 student login
import '../../../profile/presentation/providers/profile_provider.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final int assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  int? replyingToCommentId; // 🔥 untuk reply mode

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.assignmentId);
    });
  }

  void _startReply(int commentId) {
    setState(() {
      replyingToCommentId = commentId;
    });

    // auto-scroll ke bawah
    Future.delayed(const Duration(milliseconds: 200), () {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncAssignment =
        ref.watch(assignmentDetailProvider(widget.assignmentId));
    final student = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tugas')),
      body: asyncAssignment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (assignment) =>
            _buildContent(context, assignment, student),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AssignmentModel assignment,
    dynamic student,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  assignment.subjectName,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Divider(height: 32),

                _infoSection(context, assignment),

                const SizedBox(height: 24),
                const Text(
                  "Komentar",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (student == null)
                  const Center(child: CircularProgressIndicator())
                else
                  CommentListWidget(
                    postId: assignment.id,
                    currentUser: student,
                    onReplySelected: _startReply, // 🔥 tambahkan ini!
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // 🔥 Textfield komentar + Reply Bar
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: SafeArea(
            top: false,
            child: student == null
                ? const SizedBox()
                : AddCommentField(
                    postId: assignment.id,
                    commentId: replyingToCommentId,
                    onCancelReply: () {
                      setState(() => replyingToCommentId = null);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _infoSection(BuildContext context, AssignmentModel assignment) {
    final bool isSubmitted =
        assignment.status.toLowerCase().contains('sudah');
    final bool isOverdue =
        DateTime.now().isAfter(assignment.dueDate) && !isSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(
          icon: Icons.access_time,
          label: "Tenggat:",
          value: DateFormat('EEEE, dd MMMM yyyy HH:mm')
              .format(assignment.dueDate),
          color: Colors.redAccent,
        ),
        const SizedBox(height: 6),
        _infoRow(
          icon: Icons.check_circle,
          label: "Status:",
          value: assignment.status,
          bold: true,
          color: assignment.statusColor,
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool bold = false,
    Color color = Colors.black,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color),
          ),
        ),
      ],
    );
  }
}
