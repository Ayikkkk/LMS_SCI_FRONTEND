// lib/features/course/presentation/widgets/comment_list_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/providers/comment_provider.dart';
import '../../../auth/data/models/student_model.dart';

class CommentListWidget extends ConsumerWidget {
  final int postId;
  final StudentModel currentUser;
  final void Function(int commentId) onReplySelected;

  const CommentListWidget({
    super.key,
    required this.postId,
    required this.currentUser,
    required this.onReplySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentState = ref.watch(commentProvider);
    final notifier = ref.read(commentProvider.notifier);

    return commentState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text("Gagal memuat komentar")),
      data: (comments) => Column(
        children: comments.map((comment) {
          final isOwner = comment.studentId == currentUser.id;
          final replies = comment.replies;
          final replyCount = replies.length;
          final isExpanded = notifier.expandedReplies[comment.id] ?? false;

          final timestamp = comment.createdAt != null
              ? timeago.format(comment.createdAt!, locale: "id")
              : "";

          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: comment.authorPhoto != null
                      ? NetworkImage(comment.authorPhoto!)
                      : null,
                  child: comment.authorPhoto == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.authorName ?? "Tidak diketahui",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "• $timestamp",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          )
                        ],
                      ),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(comment.message),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          InkWell(
                            onTap: () => onReplySelected(comment.id),
                            child: Text(
                              "Balas",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          if (isOwner) ...[
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Hapus Komentar"),
                                    content: const Text(
                                        "Apakah kamu yakin ingin menghapus komentar ini?"),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text("Batal")),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text("Hapus"),
                                      )
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await notifier.deleteComment(comment.id);
                                }
                              },
                              child: const Icon(Icons.delete,
                                  size: 16, color: Colors.red),
                            ),
                          ]
                        ],
                      ),

                      const SizedBox(height: 6),

                      if (replyCount > 0)
                        InkWell(
                          onTap: () => notifier.toggleReplies(comment.id),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              isExpanded
                                  ? "Sembunyikan balasan"
                                  : "Lihat $replyCount balasan",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),

                      if (isExpanded)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: replies.map((reply) {
                            final replyOwner = reply.studentId == currentUser.id;
                            final replyTime = reply.createdAt != null
                                ? timeago.format(reply.createdAt!, locale: "id")
                                : "";

                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 30, top: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundImage: reply.authorPhoto != null
                                        ? NetworkImage(reply.authorPhoto!)
                                        : null,
                                    child: reply.authorPhoto == null
                                        ? const Icon(Icons.person, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                reply.authorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "• $replyTime",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                              overflow: TextOverflow.fade,
                                              softWrap: false,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(reply.message),
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (replyOwner)
                                    InkWell(
                                      onTap: () =>
                                          notifier.deleteReply(reply.id, comment.id),
                                      child: const Icon(Icons.delete,
                                          size: 14, color: Colors.red),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
