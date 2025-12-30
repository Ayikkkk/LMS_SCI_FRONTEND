import 'package:lms_frontend/features/auth/data/models/student_model.dart';
import 'dashboard_meeting_model.dart';
import 'dashboard_pending_task_model.dart';

class DashboardModel {
  final StudentModel student;
  final Stats stats;
  final List<DashboardMeetingModel> meetingsToday;
  final List<PendingTaskModel> pendingTasks; // 🔥 baru

  DashboardModel({
    required this.student,
    required this.stats,
    required this.meetingsToday,
    required this.pendingTasks, // 🔥
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      student: StudentModel.fromJson(json['student'] ?? {}),
      stats: Stats.fromJson(json['stats'] ?? {}),
      meetingsToday: (json['meetings_today'] as List? ?? [])
          .map((e) => DashboardMeetingModel.fromJson(e))
          .toList(),
      pendingTasks: (json['pending_tasks'] as List? ?? [])
          .map((e) => PendingTaskModel.fromJson(e))
          .toList(), // 🔥
    );
  }
}

// ==========================================================
// STATS
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
    double parseDouble(dynamic v) =>
        v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

    return Stats(
      totalTasks: json['total_tasks'] ?? 0,
      totalExercises: json['total_exercises'] ?? 0,
      averageTaskScore: parseDouble(json['average_task_score']),
      averageExerciseScore: parseDouble(json['average_exercise_score']),
      reportCount: json['report_count'] ?? 0,
    );
  }
}
