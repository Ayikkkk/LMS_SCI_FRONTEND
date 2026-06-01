// lib/features/course/data/repository/task_repository.dart
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/error_messages.dart';
import '../../../../core/utils/logger.dart';

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
        ApiEndpoints.assignmentStatus(assignmentId),
      );

      // Contoh response:
      // { "is_submitted": true }
      return response.data['is_submitted'] == true;
    } on DioException catch (e) {
      AppLogger.error(
        'Check submission error',
        e.response?.data,
        null,
        'TaskRepository',
      );
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

      // Web platform
      if (file.bytes != null) {
        attachment = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
          contentType: mediaType,
        );
      }
      // Mobile/Desktop platform
      else if (file.path != null) {
        attachment = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
          contentType: mediaType,
        );
      } else {
        return 'File tidak valid';
      }

      final formData = FormData.fromMap({
        'post_id': assignmentId,
        'description': description,
        'attachment': attachment,
      });

      final response = await _dio.post(
        ApiEndpoints.submitTask,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.success('Task submitted successfully', 'TaskRepository');
        return null; // sukses
      }

      return ErrorMessages.unknownError;
    } on DioException catch (e) {
      AppLogger.error(
          ErrorMessages.submitTaskFailed, e, null, 'TaskRepository');
      return ErrorMessages.fromDioException(
        e,
        fallback: ErrorMessages.submitTaskFailed,
      );
    } catch (e) {
      AppLogger.error('Unknown error', e, null, 'TaskRepository');
      return ErrorMessages.unknownError;
    }
  }

  Future<String?> updateTask({
    required int assignmentId,
    required String description,
    PlatformFile? file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'description': description,
      });

      if (file != null) {
        final mime = _guessMimeTypeFromExtension(file.name);
        final mediaType = _safeParseMimeType(mime);

        if (file.bytes != null) {
          formData.files.add(
            MapEntry(
              'attachment',
              MultipartFile.fromBytes(
                file.bytes!,
                filename: file.name,
                contentType: mediaType,
              ),
            ),
          );
        } else if (file.path != null) {
          formData.files.add(
            MapEntry(
              'attachment',
              await MultipartFile.fromFile(
                file.path!,
                filename: file.name,
                contentType: mediaType,
              ),
            ),
          );
        } else {
          return 'File tidak valid';
        }
      }

      final response = await _dio.post(
        ApiEndpoints.updateTask(assignmentId),
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.success('Task updated successfully', 'TaskRepository');
        return null;
      }

      return ErrorMessages.unknownError;
    } on DioException catch (e) {
      AppLogger.error('Update task failed', e, null, 'TaskRepository');
      return ErrorMessages.fromDioException(
        e,
        fallback: ErrorMessages.submitTaskFailed,
      );
    } catch (e) {
      AppLogger.error('Unknown error', e, null, 'TaskRepository');
      return ErrorMessages.unknownError;
    }
  }
}
