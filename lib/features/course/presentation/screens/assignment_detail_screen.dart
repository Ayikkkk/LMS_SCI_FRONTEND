// lib/features/course/presentation/screens/assignment_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../screens/submit_task_screen.dart';
import '../../domain/providers/course_providers.dart';
import '../../data/models/assignment_model.dart';

import '../../domain/providers/comment_provider.dart';
import '../../presentation/widgets/comment_list_widget.dart';
import '../../presentation/widgets/add_comment_field.dart';
import '../../../home/presentation/providers/home_provider.dart';
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
  int? replyToCommentId;
  int? editingCommentId;
  int? editingReplyId;
  String? editingInitialText;
  Timer? _refreshTimer;
  bool _listenerRegistered = false;

  int? _parsePoint(dynamic point) {
    if (point == null || point.toString().isEmpty) return null;
    return int.tryParse(point.toString());
  }

  @override
  void initState() {
    super.initState();

    /// ⏱ Backup auto refresh tiap 5 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final asyncAssignment =
          ref.read(assignmentDetailProvider(widget.assignmentId));

      asyncAssignment.whenData((assignment) {
        final score = _parsePoint(assignment.point);
        if (assignment.isSubmitted && score == null) {
          ref.invalidate(assignmentDetailProvider(widget.assignmentId));
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentProvider.notifier).loadComments(widget.assignmentId);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refreshAssignment() {
    ref.invalidate(assignmentDetailProvider(widget.assignmentId));
    ref.invalidate(dashboardAssignmentsProvider);
  }

  @override
  @override
  @override
  Widget build(BuildContext context) {
    final asyncAssignment =
        ref.watch(assignmentDetailProvider(widget.assignmentId));
    final student = ref.watch(studentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tugas')),
      body: Consumer(
        builder: (context, ref2, _) {
          ref2.listen(
            assignmentDetailProvider(widget.assignmentId),
            (prev, next) {
              next.whenData((assignment) {
                ref2.invalidate(dashboardAssignmentsProvider);
              });
            },
          );

          return asyncAssignment.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text("Gagal memuat: $e")),
            data: (assignment) => _buildContent(context, assignment, student),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AssignmentModel assignment,
    dynamic student,
  ) {
    final score = _parsePoint(assignment.point);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(assignment.subjectName,
                    style: TextStyle(color: Colors.grey.shade600)),
                const Divider(height: 32),
                _infoSection(context, assignment, score),
                const SizedBox(height: 12),
                if (!assignment.isSubmitted && !assignment.isLate)
                  ElevatedButton.icon(
                    onPressed: () async {
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
                    icon: const Icon(Icons.upload),
                    label: const Text("Kumpulkan Tugas"),
                  )
                else if (!assignment.isSubmitted && assignment.isLate)
                  _alertBox("Tugas sudah terlewat ❌", Colors.redAccent)
                else if (assignment.isSubmitted)
                  _alertBox(
                    score != null
                        ? "Tugas sudah dinilai ✔️"
                        : "Menunggu penilaian ⏳",
                    score != null ? Colors.green : Colors.orange,
                  ),
                const SizedBox(height: 20),
                const Text("Komentar",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                student == null
                    ? const Center(child: CircularProgressIndicator())
                    : CommentListWidget(
                        postId: assignment.id,
                        currentUser: student,
                        onReplySelected: (id) {
                          setState(() {
                            replyToCommentId = id;
                            editingCommentId = null;
                            editingReplyId = null;
                            editingInitialText = null;
                          });
                        },
                        onEditSelected: (id, message) {
                          setState(() {
                            editingCommentId = id;
                            editingInitialText = message;
                            replyToCommentId = null;
                            editingReplyId = null;
                          });
                        },
                        onEditReplySelected: (replyId, message, parentId) {
                          setState(() {
                            editingReplyId = replyId;
                            replyToCommentId = parentId;
                            editingInitialText = message;
                            editingCommentId = null;
                          });
                        },
                      ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        _commentInput(student, assignment),
      ],
    );
  }

  Widget _commentInput(dynamic student, AssignmentModel assignment) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: SafeArea(
        top: false,
        child: student == null
            ? const SizedBox()
            : AddCommentField(
                postId: assignment.id,
                commentId:
                    editingReplyId ?? editingCommentId ?? replyToCommentId,
                parentCommentId:
                    editingReplyId != null ? replyToCommentId : null,
                isEditing: editingCommentId != null || editingReplyId != null,
                isReply: editingReplyId != null,
                initialText: editingInitialText,
                onCancelAction: () {
                  setState(() {
                    replyToCommentId = null;
                    editingCommentId = null;
                    editingReplyId = null;
                    editingInitialText = null;
                  });
                },
              ),
      ),
    );
  }

  Widget _alertBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

Widget _infoSection(
  BuildContext context,
  AssignmentModel assignment,
  int? score,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _infoRow(
        icon: Icons.access_time,
        label: "Tenggat:",
        value: DateFormat('EEEE, dd MMM yyyy HH:mm').format(assignment.dueDate),
        color: Colors.redAccent,
      ),
      const SizedBox(height: 10),
      _infoRow(
        icon: Icons.check_circle,
        label: "Status:",
        value: assignment.status,
        bold: true,
        color: assignment.statusColor,
      ),
      if (score != null) ...[
        const SizedBox(height: 10),
        _infoRow(
          icon: Icons.grade,
          label: "Nilai:",
          value: score.toString(),
          bold: true,
          color: Colors.blue,
        ),
      ],
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
            color: color,
          ),
        ),
      )
    ],
  );
}
