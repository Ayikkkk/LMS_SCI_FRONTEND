import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_client.dart';

// ===============================================
// PROVIDER
// ===============================================

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dio = ref.read(apiClientProvider);
  return TaskRepository(dio);
});

// ===============================================
// REPOSITORY
// ===============================================

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  // =============================================================
  // Helper MIME Type
  // =============================================================

  String _guessMimeTypeFromExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'mp4':
        return 'video/mp4';
      case 'txt':
        return 'text/plain';
      case 'zip':
      case 'rar':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  MediaType _safeParseMimeType(String? mimeType) {
    if (mimeType == null || !mimeType.contains('/')) {
      return MediaType('application', 'octet-stream');
    }
    final parts = mimeType.split('/');
    return MediaType(parts[0], parts[1]);
  }

  // =============================================================
  // CHECK SUBMISSION STATUS
  // =============================================================

  Future<bool> checkSubmission(int assignmentId) async {
    try {
      final response = await _dio.get(
        'student/assignment/$assignmentId/status',
      );

      // Contoh response:
      // { "is_submitted": true }
      return response.data['is_submitted'] == true;
    } on DioException catch (e) {
      debugPrint('❌ checkSubmission error: ${e.response?.data}');
      return false;
    }
  }

  // =============================================================
  // SUBMIT TASK
  // =============================================================

  Future<String?> submitTask({
    required int assignmentId,
    required String description,
    required PlatformFile file,
  }) async {
    try {
      final mime = _guessMimeTypeFromExtension(file.name);
      final mediaType = _safeParseMimeType(mime);

      MultipartFile attachment;

      if (kIsWeb) {
        if (file.bytes == null) {
          return 'File tidak memiliki bytes.';
        }

        attachment = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: mediaType,
        );
      } else {
        if (file.path == null) {
          return 'Path file tidak ditemukan.';
        }

        attachment = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
          contentType: mediaType,
        );
      }

      final formData = FormData.fromMap({
        'post_id': assignmentId,
        'description': description,
        'attachment': attachment,
      });

      final response = await _dio.post(
        'student/submit-task',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // sukses
      }

      return 'Server error (${response.statusCode})';
    } on DioException catch (e) {
      final msg = e.response?.data.toString() ?? e.message;
      return 'Gagal submit: $msg';
    } catch (e) {
      return 'Error tidak diketahui: $e';
    }
  }
}
