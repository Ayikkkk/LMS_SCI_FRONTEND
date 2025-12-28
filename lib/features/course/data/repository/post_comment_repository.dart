import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/post_comment_model.dart';
import '../models/post_child_comment_model.dart';

final postCommentRepositoryProvider = Provider<PostCommentRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PostCommentRepository(dio);
});

class PostCommentRepository {
  final Dio dio;

  PostCommentRepository(this.dio);

  /// Ambil daftar komentar & balasan
  Future<List<PostComment>> getComments(int postId) async {
    try {
      final response = await dio.get("student/posts/$postId/comments");
      final List data = response.data['comments'] ?? [];
      return data.map((json) => PostComment.fromJson(json)).toList();
    } catch (_) {
      throw Exception("Gagal memuat komentar");
    }
  }

  /// Tambah komentar utama
  Future<PostComment> addComment(int postId, String message) async {
    try {
      final response = await dio.post(
        "student/posts/$postId/comments",
        data: {'message': message},
      );

      return PostComment.fromJson(response.data['data']);
    } catch (_) {
      throw Exception("Gagal menambah komentar");
    }
  }

  /// Tambah balasan
  Future<PostChildComment> addReply(int commentId, String message) async {
    try {
      final response = await dio.post(
        "student/comments/$commentId/reply",
        data: {'message': message},
      );

      return PostChildComment.fromJson(response.data['data']);
    } catch (_) {
      throw Exception("Gagal menambah balasan");
    }
  }

  /// Hapus komentar utama
  Future<bool> deleteComment(int commentId) async {
    try {
      final response = await dio.delete("student/comments/$commentId");

      return response.statusCode == 200 ||
             response.statusCode == 201 ||
             response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Hapus balasan komentar
  Future<bool> deleteReply(int replyId) async {
    try {
      final response = await dio.delete("student/replies/$replyId");

      return response.statusCode == 200 ||
             response.statusCode == 201 ||
             response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
