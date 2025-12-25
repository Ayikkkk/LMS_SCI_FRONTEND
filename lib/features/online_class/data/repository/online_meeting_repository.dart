// lib/features/online_class/data/repository/online_meeting_repository.dart

import 'package:dio/dio.dart';
import '../models/online_meeting_model.dart';

class OnlineMeetingRepository {
  final Dio dio;

  OnlineMeetingRepository(this.dio);

  Future<List<OnlineMeetingModel>> fetchMeetings() async {
    final response = await dio.get('/student/meetings');

    final List data = response.data['data'];
    return data.map((e) => OnlineMeetingModel.fromJson(e)).toList();
  }

  Future<String> joinMeeting(int meetingId) async {
    final response = await dio.post('/student/meetings/$meetingId/join');

    return response.data['jitsi_url'];
  }
}
