// lib/features/home/data/models/dashboard_meeting_model.dart

class DashboardMeetingModel {
  final int id;
  final String title;
  final String platform;
  final DateTime startTime; // SUDAH LOCAL (WIB)
  final DateTime? endTime;
  final String status; // upcoming | live | ended
  final String meetingCode;

  DashboardMeetingModel({
    required this.id,
    required this.title,
    required this.platform,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.meetingCode,
  });

  factory DashboardMeetingModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['start_time'];

    return DashboardMeetingModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '-',
      platform: 'Online',
      meetingCode: json['meeting_code'] ?? '',

      // Backend mengirim ISO 8601 dengan timezone WIB (+07:00)
      // DateTime.parse menghasilkan UTC DateTime, .toLocal() convert ke local device (WIB)
      startTime: DateTime.parse(rawStart).toLocal(),

      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time']).toLocal()
          : null,

      status: (json['status'] ?? 'upcoming').toString().toLowerCase(),
    );
  }

  // ===================================================
  // 🔹 STATUS HELPERS
  // ===================================================

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isEnded => status == 'ended';
  bool get isActive => isLive || isUpcoming;

  String get statusLabel {
    switch (status) {
      case 'live':
        return 'LIVE';
      case 'upcoming':
        return 'UPCOMING';
      default:
        return 'ENDED';
    }
  }

  // ===================================================
  // ⏱ COUNTDOWN (AKURAT WIB)
  // ===================================================

  Duration get timeToStart => startTime.difference(DateTime.now());

  bool get hasStarted => timeToStart.isNegative;

  String get countdownLabel {
    if (isLive) return 'LIVE';

    final diff = timeToStart;
    if (diff.isNegative) return 'Mulai';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return '$hours jam $minutes mnt';
    }
    return '$minutes mnt lagi';
  }
}
