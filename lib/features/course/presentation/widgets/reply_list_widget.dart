import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/comment_provider.dart';
import '../../../../features/auth/data/models/student_model.dart';
import '../../../../features/course/data/models/post_comment_model.dart';
import 'add_reply_field.dart';

class ReplyListWidget extends ConsumerWidget {
  final PostComment comment;
  final StudentModel currentUser;

  const ReplyListWidget({
    super.key,
    required this.comment,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = ref.watch(commentProvider.notifier)
        .isExpanded(comment.id);

    final replies = comment.replies;

    if (replies.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleReplies = isExpanded
        ? replies
        : [replies.last]; // tampil hanya balasan terbaru

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === List Balasan ===
        ...visibleReplies.map((reply) {
          final isReplyOwner = reply.authorName == currentUser.name;

          return Container(
            margin: const EdgeInsets.only(left: 20, top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(reply.message)),
                if (isReplyOwner)
                  InkWell(
                    onTap: () {
                      ref.read(commentProvider.notifier)
                          .deleteReply(comment.id, reply.id);
                    },
                    child: const Icon(Icons.delete,
                        size: 16, color: Colors.red),
                  )
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 6),

        // === Tombol Expand/Collapse ===
        if (replies.length > 1)
          GestureDetector(
            onTap: () {
              ref.read(commentProvider.notifier)
                  .toggleReplyVisibility(comment.id);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                isExpanded
                    ? "Sembunyikan balasan"
                    : "Lihat ${replies.length - 1} balasan lainnya...",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),

        // === Field Balas ===
        AddReplyField(commentId: comment.id),
      ],
    );
  }
}
