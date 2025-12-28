import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_comment_model.dart';
import '../../data/repository/post_comment_repository.dart';

class CommentNotifier extends StateNotifier<AsyncValue<List<PostComment>>> {
  CommentNotifier(this._repository) : super(const AsyncValue.loading());

  final PostCommentRepository _repository;

  /// Simpan state expand/collapse per komentar
  final Map<int, bool> _expandedReplies = {};
  Map<int, bool> get expandedReplies => _expandedReplies;

  /// Check expanded state
  bool isExpanded(int commentId) => _expandedReplies[commentId] ?? false;

  /// Toggle replies (alias)
  void toggleReplyVisibility(int commentId) => toggleReplies(commentId);

  /// Show / Hide replies
  void toggleReplies(int commentId) {
    _expandedReplies[commentId] = !(_expandedReplies[commentId] ?? false);
    state = state.whenData((comments) => [...comments]); // refresh UI
  }

  /// Load all comments
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

  /// Add new comment
  Future<void> addComment(int postId, String message) async {
    try {
      final newComment = await _repository.addComment(postId, message);

      state = state.whenData((comments) => [...comments, newComment]);
      _expandedReplies[newComment.id] = false;
    } catch (_) {}
  }

  /// Add reply
  Future<void> addReply(int commentId, String message) async {
    try {
      final reply = await _repository.addReply(commentId, message);

      state = state.whenData((comments) {
        return comments.map((comment) {
          if (comment.id == commentId) {
            return comment.copyWith(replies: [...comment.replies, reply]);
          }
          return comment;
        }).toList();
      });

      /// Tetap collapsed setelah membalas
      _expandedReplies[commentId] = false;

    } catch (_) {}
  }

  /// Delete comment (only if own)
  Future<void> deleteComment(int commentId) async {
    try {
      final success = await _repository.deleteComment(commentId);
      if (!success) return;

      state = state.whenData(
        (comments) => comments.where((c) => c.id != commentId).toList(),
      );

      _expandedReplies.remove(commentId);

    } catch (_) {}
  }

  /// Delete reply
  Future<void> deleteReply(int replyId, int commentId) async {
    try {
      final success = await _repository.deleteReply(replyId);
      if (!success) return;

      state = state.whenData((comments) {
        return comments.map((comment) {
          if (comment.id == commentId) {
            final updatedReplies =
                comment.replies.where((r) => r.id != replyId).toList();
            return comment.copyWith(replies: updatedReplies);
          }
          return comment;
        }).toList();
      });

      /// Tetap collapsed setelah delete
      _expandedReplies[commentId] = false;

    } catch (_) {}
  }
}

final commentProvider =
    StateNotifierProvider<CommentNotifier, AsyncValue<List<PostComment>>>(
  (ref) => CommentNotifier(ref.watch(postCommentRepositoryProvider)),
);
