import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/comment_provider.dart';

class AddReplyField extends ConsumerStatefulWidget {
  final int commentId;

  const AddReplyField({super.key, required this.commentId});

  @override
  ConsumerState<AddReplyField> createState() => _AddReplyFieldState();
}

class _AddReplyFieldState extends ConsumerState<AddReplyField> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  Future<void> _sendReply() async {
    if (_controller.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);

    try {
      await ref.read(commentProvider.notifier)
          .addReply(widget.commentId, _controller.text.trim());
      _controller.clear();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengirim balasan"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_loading,
            decoration: InputDecoration(
              hintText: "Balas komentar...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendReply,
              )
      ],
    );
  }
}
