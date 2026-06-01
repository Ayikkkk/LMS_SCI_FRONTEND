// lib/features/online_class/data/repository/online_meeting_repository.dart

import 'package:dio/dio.dart';
import '../../../../core/constants/error_messages.dart';
import '../models/online_meeting_model.dart';

class MeetingJoinResponse {
  final String meetingCode;
  final String jitsiUrl;

  MeetingJoinResponse({
    required this.meetingCode,
    required this.jitsiUrl,
  });

  factory MeetingJoinResponse.fromJson(Map<String, dynamic> json) {
    return MeetingJoinResponse(
      meetingCode: json['meeting_code'],
      jitsiUrl: json['jitsi_url'],
    );
  }
}

class OnlineMeetingRepository {
  final Dio dio;
  OnlineMeetingRepository(this.dio);

  /// 🔹 Ambil daftar meeting siswa
  Future<List<OnlineMeetingModel>> fetchMeetings() async {
    final response = await dio.get('/student/meetings');

    if (response.data['success'] != true) {
      throw Exception('Gagal mengambil data meeting');
    }

    return (response.data['data'] as List)
        .map((e) => OnlineMeetingModel.fromJson(e))
        .toList();
  }

  /// 🔹 Join meeting (insert participant siswa)
  Future<MeetingJoinResponse> joinMeeting(int meetingId) async {
    try {
      final response = await dio.post('/student/meetings/$meetingId/join');

      if (response.data['success'] == true) {
        return MeetingJoinResponse.fromJson(response.data);
      }

      throw Exception(response.data['message'] ?? 'Gagal join meeting');
    } on DioException catch (e) {
      final message = ErrorMessages.fromDioException(
        e,
        fallback: 'Meeting belum dimulai',
      );
      throw Exception(message);
    }
  }

  /// 🔹 Leave meeting (update left_at)
  Future<void> leaveMeeting(int meetingId) async {
    await dio.post('/student/meetings/$meetingId/leave');
  }
}
