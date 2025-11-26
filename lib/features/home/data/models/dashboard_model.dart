// lib/features/home/data/models/dashboard_model.dart

// 💡 PENTING: Pastikan Anda mengimpor StudentModel dengan path yang benar
import 'package:lms_frontend/features/auth/data/models/student_model.dart';


// ==========================================================
// 1. MODEL UTAMA: DashboardModel
// ==========================================================

class DashboardModel {
  // Menggunakan StudentModel (dari fitur auth) sebagai sumber data siswa
  final StudentModel student;
  final Stats stats;
  final List<OnlineMeetingModel> meetingsToday;

  DashboardModel({
    required this.student,
    required this.stats,
    required this.meetingsToday,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    // Parsing daftar meetings
    var list = json['meetings_today'] as List? ?? [];
    List<OnlineMeetingModel> meetingsList = list.map((i) => OnlineMeetingModel.fromJson(i as Map<String, dynamic>)).toList();

    return DashboardModel(
      // Panggil fromJson dari StudentModel
      student: StudentModel.fromJson(json['student'] as Map<String, dynamic>? ?? {}),
      stats: Stats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
      meetingsToday: meetingsList,
    );
  }
}

// ==========================================================
// 2. SUB-MODEL: Model Statistik
// ==========================================================

class Stats {
  final int totalTasks;
  final int totalExercises;
  final double averageTaskScore;
  final double averageExerciseScore;
  final int reportCount;

  Stats({
    required this.totalTasks,
    required this.totalExercises,
    required this.averageTaskScore,
    required this.averageExerciseScore,
    required this.reportCount,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengkonversi nilai (int/String) menjadi double dengan aman
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Stats(
      totalTasks: json['total_tasks'] as int? ?? 0,
      totalExercises: json['total_exercises'] as int? ?? 0,

      averageTaskScore: _parseDouble(json['average_task_score']),
      averageExerciseScore: _parseDouble(json['average_exercise_score']),

      reportCount: json['report_count'] as int? ?? 0,
    );
  }
}

// ==========================================================
// 3. SUB-MODEL: Model Meeting Hari Ini
// ==========================================================

class OnlineMeetingModel {
  final int id;
  final String title;
  final String platform;
  final String meetingLink;
  final String startTime;
  final String endTime;

  OnlineMeetingModel({
    required this.id,
    required this.title,
    required this.platform,
    required this.meetingLink,
    required this.startTime,
    required this.endTime,
  });

  factory OnlineMeetingModel.fromJson(Map<String, dynamic> json) {
    return OnlineMeetingModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Kelas Tanpa Nama',
      platform: json['platform'] as String? ?? 'Zoom/GMeet',
      meetingLink: json['meeting_link'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
    );
  }
}