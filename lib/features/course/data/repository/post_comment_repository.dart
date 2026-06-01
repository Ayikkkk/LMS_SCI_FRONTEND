// lib/features/course/data/repository/post_comment_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/error_messages.dart';
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
    } on DioException catch (e) {
      throw Exception(ErrorMessages.fromDioException(e));
    } catch (_) {
      throw Exception(ErrorMessages.unknownError);
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
    } on DioException catch (e) {
      throw Exception(ErrorMessages.fromDioException(e));
    } catch (_) {
      throw Exception(ErrorMessages.unknownError);
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
    } on DioException catch (e) {
      throw Exception(ErrorMessages.fromDioException(e));
    } catch (_) {
      throw Exception(ErrorMessages.unknownError);
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

  /// 🔹 Edit komentar utama
  Future<PostComment?> updateComment(int commentId, String message) async {
    try {
      final response = await dio.put(
        "student/comments/$commentId",
        data: {'message': message},
      );

      if (response.data['success'] == true) {
        return PostComment.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 🔹 Edit balasan komentar
  Future<PostChildComment?> updateReply(int replyId, String message) async {
    try {
      final response = await dio.put(
        "student/replies/$replyId",
        data: {'message': message},
      );

      if (response.data['success'] == true) {
        return PostChildComment.fromJson(response.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
