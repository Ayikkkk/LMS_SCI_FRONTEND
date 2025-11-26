import 'package:lms_frontend/features/auth/data/models/student_model.dart';

// Model Utama
class DashboardModel {
  // Ganti StudentInfo menjadi StudentModel
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
    var list = json['meetings_today'] as List;
    List<OnlineMeetingModel> meetingsList = list.map((i) => OnlineMeetingModel.fromJson(i)).toList();

    return DashboardModel(
      // Panggil fromJson dari StudentModel yang sudah diimpor
      student: StudentModel.fromJson(json['student']),
      stats: Stats.fromJson(json['stats']),
      meetingsToday: meetingsList,
    );
  }
}

// Model Statistik (Stats)
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
    return Stats(
      totalTasks: json['total_tasks'] as int? ?? 0,
      totalExercises: json['total_exercises'] as int? ?? 0,

      // Mengatasi kemungkinan data datang sebagai String/int sebelum dikonversi ke double
      averageTaskScore: double.tryParse(json['average_task_score']?.toString() ?? '0') ?? 0.0,
      averageExerciseScore: double.tryParse(json['average_exercise_score']?.toString() ?? '0') ?? 0.0,

      reportCount: json['report_count'] as int? ?? 0,
    );
  }
}

// Model Meeting Hari Ini (OnlineMeetingModel)
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
