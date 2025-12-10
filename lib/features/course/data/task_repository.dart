import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const String _baseUrl = 'http://192.168.1.8:8000/api/';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

class TaskRepository {
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

  MediaType _safeParseMimeType(String? mimeType,
      [String defaultType = 'application/octet-stream']) {
    if (mimeType == null || mimeType.isEmpty) {
      return MediaType.parse(defaultType);
    }

    final p = mimeType.split('/');
    if (p.length != 2 || p[0].isEmpty || p[1].isEmpty) {
      return MediaType.parse(defaultType);
    }

    return MediaType(p[0], p[1]);
  }

  // =============================================================
  //  CHECK SUBMISSION STATUS
  // =============================================================
  Future<bool> checkSubmission(int assignmentId, String authToken) async {
    final url = Uri.parse('${_baseUrl}student/assignment/$assignmentId/status');

    try {
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (res.statusCode == 200) {
        final body = res.body;

        // Contoh response backend:
        // { "is_submitted": true }

        return body.contains('true');
      }

      return false; // default: dianggap belum mengumpulkan
    } catch (e) {
      print("⚠️ Error checkSubmission: $e");
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
    required String authToken,
  }) async {
    final url = Uri.parse('${_baseUrl}student/submit-task');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $authToken';

    request.fields['post_id'] = assignmentId.toString();
    request.fields['description'] = description;

    try {
      final mime = _guessMimeTypeFromExtension(file.name);
      final safeMime = _safeParseMimeType(mime);

      http.MultipartFile attachment;

      if (kIsWeb || file.path == null) {
        if (file.bytes == null) {
          return 'File tidak memiliki bytes.';
        }

        attachment = http.MultipartFile.fromBytes(
          'attachment',
          file.bytes!,
          filename: file.name,
          contentType: safeMime,
        );
      } else {
        attachment = await http.MultipartFile.fromPath(
          'attachment',
          file.path!,
          filename: file.name,
          contentType: safeMime,
        );
      }

      request.files.add(attachment);
    } catch (e) {
      return 'Gagal menyiapkan file: $e';
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // sukses
      } else {
        return 'Server Error (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      return 'Koneksi gagal: $e';
    }
  }
}
