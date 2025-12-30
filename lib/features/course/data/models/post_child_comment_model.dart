import '../../../../core/network/api_client.dart';

class PostChildComment {
  final int id;
  final int? postCommentId;
  final int? userId;
  final int? studentId;
  final String message;
  final String authorName;
  final String authorPhoto;
  final bool isUser;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PostChildComment({
    required this.id,
    this.postCommentId,
    this.userId,
    this.studentId,
    required this.message,
    required this.authorName,
    required this.authorPhoto,
    required this.isUser,
    this.createdAt,
    this.updatedAt,
  });

  factory PostChildComment.fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final user = json['user'];

    final rawPhoto = student?['photo'] ??
        student?['photo_url'] ??
        user?['photo'] ??
        user?['img'] ??
        json['author_photo'];

    String resolvedPhoto;
    if (rawPhoto != null) {
      if (rawPhoto.startsWith('http')) {
        resolvedPhoto = rawPhoto;
      } else {
        resolvedPhoto =
            "$apiHost/storage/${rawPhoto.replaceAll(RegExp(r'^/+'), '')}";
      }
    } else {
      resolvedPhoto = "https://ui-avatars.com/api/?name=User";
    }

    return PostChildComment(
      id: json['id'],
      postCommentId: json['post_comment_id'],
      userId: json['user_id'],
      studentId: json['student_id'],
      message: json['message'] ?? '',
      authorName: student?['name'] ??
          user?['name'] ??
          json['author_name'] ??
          "Tidak diketahui",
      authorPhoto: resolvedPhoto,
      isUser: json['is_user'] == true || json['is_user'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Format timestamp UI
  String timeAgo() {
    if (createdAt == null) return "";
    final diff = DateTime.now().difference(createdAt!);

    if (diff.inSeconds < 60) return "Baru saja";
    if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
    if (diff.inHours < 24) return "${diff.inHours} jam lalu";
    if (diff.inDays == 1) return "Kemarin";
    if (diff.inDays < 7) return "${diff.inDays} hari lalu";
    return "${createdAt!.day}-${createdAt!.month}-${createdAt!.year}";
  }

  /// ✨ copyWith: penting untuk update UI tanpa reload
  PostChildComment copyWith({
    String? message,
    DateTime? updatedAt,
  }) {
    return PostChildComment(
      id: id,
      postCommentId: postCommentId,
      userId: userId,
      studentId: studentId,
      message: message ?? this.message,
      authorName: authorName,
      authorPhoto: authorPhoto,
      isUser: isUser,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
