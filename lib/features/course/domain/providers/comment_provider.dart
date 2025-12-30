import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_comment_model.dart';
import '../../data/models/post_child_comment_model.dart';
import '../../data/repository/post_comment_repository.dart';

class CommentNotifier extends StateNotifier<AsyncValue<List<PostComment>>> {
  CommentNotifier(this._repository) : super(const AsyncValue.loading());

  final PostCommentRepository _repository;

  final Map<int, bool> _expandedReplies = {};
  Map<int, bool> get expandedReplies => _expandedReplies;

  bool isExpanded(int id) => _expandedReplies[id] ?? false;

  void toggleReplies(int id) {
    _expandedReplies[id] = !(_expandedReplies[id] ?? false);
    state = state.whenData((comments) => [...comments]);
  }

  Future<void> loadComments(int postId) async {
    try {
      state = const AsyncValue.loading();
      final comments = await _repository.getComments(postId);
      state = AsyncValue.data(comments);

      _expandedReplies.clear();
      for (var c in comments) {
        _expandedReplies[c.id] = false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addComment(int postId, String message) async {
    try {
      final newComment = await _repository.addComment(postId, message);
      state = state.whenData((comments) => [...comments, newComment]);
      _expandedReplies[newComment.id] = false;
    } catch (_) {}
  }

  Future<void> addReply(int parentId, String message) async {
    try {
      final reply = await _repository.addReply(parentId, message);

      state = state.whenData((comments) {
        return comments.map((c) {
          if (c.id == parentId) {
            return c.copyWith(replies: [...c.replies, reply]);
          }
          return c;
        }).toList();
      });

      _expandedReplies[parentId] = true;
    } catch (_) {}
  }

  Future<void> deleteComment(int id) async {
    final success = await _repository.deleteComment(id);
    if (!success) return;

    state = state.whenData(
      (comments) => comments.where((c) => c.id != id).toList(),
    );
    _expandedReplies.remove(id);
  }

  Future<void> deleteReply(int replyId, int parentId) async {
    final success = await _repository.deleteReply(replyId);
    if (!success) return;

    state = state.whenData((comments) {
      return comments.map((c) {
        if (c.id == parentId) {
          final updatedReplies =
              c.replies.where((r) => r.id != replyId).toList();
          return c.copyWith(replies: updatedReplies);
        }
        return c;
      }).toList();
    });

    _expandedReplies[parentId] = false;
  }

  // =====================================
  // ✨ Update Comment + Reply
  // =====================================

  // 🔹 Update komentar utama
  Future<void> updateComment(int id, String message) async {
    final updated = await _repository.updateComment(id, message);

    if (updated == null) return;

    state = state.whenData((comments) {
      return comments.map((c) {
        return c.id == id
            ? c.copyWith(
                message: updated.message,
                updatedAt: DateTime.now(),
              )
            : c;
      }).toList();
    });
  }

// 🔹 Update balasan komentar
  Future<void> updateReply(int replyId, int parentId, String message) async {

    final updatedReply = await _repository.updateReply(replyId, message);
    if (updatedReply == null) return;
    state = state.whenData((comments) {
      return comments.map((c) {
        if (c.id == parentId) {
          return c.copyWith(
            replies: c.replies.map((r) {
              return r.id == replyId ? updatedReply : r;
            }).toList(),
          );
        }
        return c;
      }).toList();
    });
  }
}

final commentProvider =
    StateNotifierProvider<CommentNotifier, AsyncValue<List<PostComment>>>(
        (ref) => CommentNotifier(ref.watch(postCommentRepositoryProvider)));
