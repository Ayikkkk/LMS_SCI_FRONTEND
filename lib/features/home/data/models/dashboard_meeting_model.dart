class DashboardMeetingModel {
  final int id;
  final String title;
  final String platform;
  final DateTime startTime;
  final DateTime? endTime;

  DashboardMeetingModel({
    required this.id,
    required this.title,
    required this.platform,
    required this.startTime,
    this.endTime,
  });

  factory DashboardMeetingModel.fromJson(Map<String, dynamic> json) {
    return DashboardMeetingModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '-',
      platform: json['platform'] ?? 'Online',
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
    );
  }
}
