import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/error_messages.dart';
import '../../domain/providers/comment_provider.dart';

class AddCommentField extends ConsumerStatefulWidget {
  final int postId;
  final int? commentId; // id comment or reply
  final bool isEditing;
  final bool isReply; // 🔥 baruuuu
  final int? parentCommentId; // 🔥 khusus edit balasan
  final String? initialText;
  final VoidCallback? onCancelAction;

  const AddCommentField({
    super.key,
    required this.postId,
    this.commentId,
    this.isEditing = false,
    this.isReply = false, // default: bukan reply edit
    this.parentCommentId,
    this.initialText,
    this.onCancelAction,
  });

  @override
  ConsumerState<AddCommentField> createState() => _AddCommentFieldState();
}

class _AddCommentFieldState extends ConsumerState<AddCommentField> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void didUpdateWidget(covariant AddCommentField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isEditing &&
        widget.initialText != null &&
        widget.initialText != _controller.text) {
      _controller.text = widget.initialText!;
    }

    if (!widget.isEditing && widget.commentId == null) {
      _controller.clear();
    }
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final notifier = ref.read(commentProvider.notifier);

    try {
      if (widget.isEditing && widget.commentId != null) {
        if (widget.isReply && widget.parentCommentId != null) {
          /// 🔥 Edit balasan komentar
          await notifier.updateReply(
            widget.commentId!,
            widget.parentCommentId!,
            text,
          );
        } else {
          /// Edit komentar utama
          await notifier.updateComment(widget.commentId!, text);
        }

        //  Reset UI di semиa kasus update (utama / balasan)
        widget.onCancelAction?.call();
      } else if (widget.commentId != null) {
        /// Tambah balasan komentar
        await notifier.addReply(widget.commentId!, text);
        widget.onCancelAction?.call();
      } else {
        /// Tambah komentar baru
        await notifier.addComment(widget.postId, text);
      }

      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessages.fromException(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showActionBar = widget.commentId != null;

    return Column(
      children: [
        if (showActionBar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: widget.isEditing
                  ? Colors.orange.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isEditing
                      ? (widget.isReply
                          ? "Mengedit balasan…"
                          : "Mengedit komentar…")
                      : "Membalas komentar…",
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isEditing ? Colors.orange : Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: widget.onCancelAction,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
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
                    hintText: widget.isEditing
                        ? "Perbarui pesan..."
                        : (widget.commentId == null
                            ? "Tulis komentar…"
                            : "Balas komentar…"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      icon: Icon(widget.isEditing ? Icons.check : Icons.send),
                      color: widget.isEditing ? Colors.orange : Colors.blue,
                      tooltip: widget.isEditing
                          ? 'Simpan perubahan'
                          : 'Kirim komentar',
                      onPressed: _sendComment,
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
