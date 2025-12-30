// lib/features/course/presentation/widgets/reply_list_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/providers/comment_provider.dart';
import '../../../../features/auth/data/models/student_model.dart';
import '../../../../features/course/data/models/post_comment_model.dart';

class ReplyListWidget extends ConsumerWidget {
  final PostComment comment;
  final StudentModel currentUser;

  /// 🔥 Callback edit reply
  final void Function(int replyId, String message)? onEditReplySelected;

  const ReplyListWidget({
    super.key,
    required this.comment,
    required this.currentUser,
    this.onEditReplySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(commentProvider.notifier);
    final isExpanded = notifier.isExpanded(comment.id);
    final replies = comment.replies;

    if (replies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔥 LIST BALASAN
        ...replies.map((reply) {
          final isOwner = reply.studentId == currentUser.id;
          final replyTime = reply.createdAt != null
              ? timeago.format(reply.createdAt!, locale: "id")
              : "";

          return Padding(
            padding: const EdgeInsets.only(left: 30, top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Avatar
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

                /// Bubble Reply
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
                              color: Colors.grey,
                            ),
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

                      /// ACTIONS OF REPLY
                      if (isOwner)
                        Row(
                          children: [
                            /// ✏ EDIT
                            InkWell(
                              onTap: () => onEditReplySelected?.call(
                                reply.id,
                                reply.message,
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.orange),
                            ),
                            const SizedBox(width: 10),

                            /// 🗑 DELETE
                            InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Hapus Balasan"),
                                    content: const Text(
                                      "Yakin ingin menghapus balasan ini?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Batal"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red),
                                        child: const Text("Hapus"),
                                      )
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  notifier.deleteReply(
                                      reply.id, comment.id);
                                }
                              },
                              child: const Icon(Icons.delete,
                                  size: 14, color: Colors.red),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 6),

        /// Toggle SHOW/HIDE Replies
        if (replies.length > 1)
          InkWell(
            onTap: () =>
                ref.read(commentProvider.notifier)
                    .toggleReplies(comment.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                isExpanded
                    ? "Sembunyikan balasan"
                    : "Lihat ${replies.length - 1} balasan",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
