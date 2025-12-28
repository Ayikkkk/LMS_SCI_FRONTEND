// lib/features/online_class/data/models/online_meeting_model.dart

class OnlineMeetingModel {
  final int id;
  final int classroomId;
  final String title;
  final String? description;
  final String meetingCode;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;

  OnlineMeetingModel({
    required this.id,
    required this.classroomId,
    required this.title,
    this.description,
    required this.meetingCode,
    this.startTime,
    this.endTime,
    required this.status,
  });

  factory OnlineMeetingModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final s = value.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return OnlineMeetingModel(
      id: json['id'],
      classroomId: json['classroom_id'],
      title: json['title'],
      description: json['description'],
      meetingCode: json['meeting_code'],
      startTime: parseDate(json['start_time']),
      endTime: parseDate(json['end_time']),
      status: json['status'],
    );
  }

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isEnded => status == 'ended';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classroom_id': classroomId,
      'title': title,
      'description': description,
      'meeting_code': meetingCode,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status,
    };
  }
}
