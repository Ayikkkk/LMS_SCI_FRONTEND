import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/comment_provider.dart';

class AddCommentField extends ConsumerStatefulWidget {
  final int postId;
  final int? commentId; // null = komentar utama
  final VoidCallback? onCancelReply; // 🔥 Tambahan untuk keluar mode reply

  const AddCommentField({
    super.key,
    required this.postId,
    this.commentId,
    this.onCancelReply,
  });

  @override
  ConsumerState<AddCommentField> createState() =>
      _AddCommentFieldState();
}

class _AddCommentFieldState extends ConsumerState<AddCommentField> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      if (widget.commentId == null) {
        await ref.read(commentProvider.notifier)
            .addComment(widget.postId, text);
      } else {
        await ref.read(commentProvider.notifier)
            .addReply(widget.commentId!, text);

        // 🔥 Keluar mode balas setelah berhasil
        widget.onCancelReply?.call();
      }

      _controller.clear();

    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengirim komentar"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🔥 Jika dalam mode balasan, tampilkan bar di atas input
        if (widget.commentId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Membalas komentar...",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: widget.onCancelReply,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: Colors.red),
                  ),
                )
              ],
            ),
          ),

        SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    hintText: widget.commentId == null
                        ? "Tulis komentar…"
                        : "Balas komentar…",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _loading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
                      onPressed: _sendComment,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
