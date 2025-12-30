import 'post_child_comment_model.dart';
import '../../../../core/network/api_client.dart';

class PostComment {
  final int id;
  final int? postId;
  final int? userId;
  final int? studentId;
  final String message;
  final String? authorName;
  final String? authorPhoto;
  final bool isUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PostChildComment> replies;

  PostComment({
    required this.id,
    this.postId,
    this.userId,
    this.studentId,
    required this.message,
    this.authorName,
    this.authorPhoto,
    required this.isUser,
    this.createdAt,
    this.updatedAt,
    required this.replies,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final user = json['user'];

    // 🔥 Ambil semua kemungkinan field foto
    final rawPhoto = student?['photo'] ??
        student?['photo_url'] ??
        user?['photo'] ??
        user?['img'] ??
        json['author_photo'];

    String? resolvedPhoto;
    if (rawPhoto != null) {
      if (rawPhoto.startsWith('http')) {
        resolvedPhoto = rawPhoto;
      } else {
        resolvedPhoto =
            "$apiHost/storage/${rawPhoto.replaceAll(RegExp(r'^/+'), '')}";
      }
    }

    return PostComment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      studentId: json['student_id'],
      message: json['message'] ?? '',
      authorName: student?['name'] ??
          user?['name'] ??
          json['author_name'] ??
          "Tidak diketahui",
      authorPhoto: resolvedPhoto,
      isUser: json['is_user'] == 1 || json['is_user'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      replies: (json['replies'] as List? ?? [])
          .map((e) => PostChildComment.fromJson(e))
          .toList(),
    );
  }

  /// Format timestamp ala aplikasi chat
  String timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";
    if (diff.inDays == 1) return "Kemarin";
    if (diff.inDays < 7) return "${diff.inDays} hari lalu";
    return "${dateTime.day}-${dateTime.month}-${dateTime.year}";
  }

  PostComment copyWith({
    String? message,
    DateTime? updatedAt,
    List<PostChildComment>? replies,
  }) {
    return PostComment(
      id: id,
      postId: postId,
      userId: userId,
      studentId: studentId,
      message: message?? this.message,
      authorName: authorName,
      authorPhoto: authorPhoto,
      isUser: isUser,
      createdAt: createdAt,
      updatedAt: updatedAt?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }
}
