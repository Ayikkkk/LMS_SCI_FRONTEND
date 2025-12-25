// lib/features/online_class/data/models/online_meeting_model.dart

class OnlineMeetingModel {
  final int id;
  final String title;
  final String description;
  final String meetingCode;
  final DateTime startTime;
  final String status;

  OnlineMeetingModel({
    required this.id,
    required this.title,
    required this.description,
    required this.meetingCode,
    required this.startTime,
    required this.status,
  });

  factory OnlineMeetingModel.fromJson(Map<String, dynamic> json) {
    return OnlineMeetingModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      meetingCode: json['meeting_code'],
      startTime: DateTime.parse(json['start_time']),
      status: json['status'],
    );
  }
}
