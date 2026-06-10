import 'package:flutter/material.dart';

class AssignmentModel {
  final int id;
  final int mapelId;
  final String subjectName;
  final String title;
  final String? description;
  final DateTime? dueDate; // nullable — tugas mungkin tidak punya deadline

  /// Status
  final int? taskId;
  final bool isSubmitted;
  final String status;
  final Color statusColor;

  /// Classroom spesifik (null = semua kelas)
  final int? classroomId;

  /// File yang dikirim siswa
  final String? studentDescription;
  final String? studentAttachment;
  final DateTime? submittedAt;
  final DateTime? submissionUpdatedAt;

  final String? link;
  final String? attachment;
  final String? embed;
  final String point;

  AssignmentModel({
    required this.id,
    required this.mapelId,
    required this.subjectName,
    required this.title,
    this.description,
    this.dueDate,
    this.taskId,
    required this.isSubmitted,
    required this.status,
    required this.statusColor,
    this.classroomId,
    this.studentDescription,
    this.studentAttachment,
    this.submittedAt,
    this.submissionUpdatedAt,
    required this.point,
    this.link,
    this.attachment,
    this.embed,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final DateTime now = DateTime.now();

    /// Parsing due date — nullable
    DateTime? dueDate;
    try {
      if (json['due_date'] != null) {
        dueDate = DateTime.parse(json['due_date'].toString()).toLocal();
      }
    } catch (_) {
      dueDate = null;
    }

    /// Status pengumpulan
    final bool isSubmitted =
        json['is_submitted'] == 1 || json['is_submitted'] == true;

    /// Logika Nilai (Point)
    // Jika null, 0, atau string kosong, tampilkan "-"
    String pointDisplay = "-";
    if (json['point'] != null && json['point'] != 0 && json['point'] != "0") {
      pointDisplay = json['point'].toString();
    }

    /// File tugas siswa
    String? studentAttachment;
    if (json['student_attachment'] != null &&
        json['student_attachment'].toString().isNotEmpty) {
      studentAttachment = json['student_attachment'];
    }

    DateTime? submittedAt;
    DateTime? submissionUpdatedAt;
    try {
      if (json['submitted_at'] != null) {
        submittedAt = DateTime.parse(json['submitted_at'].toString()).toLocal();
      }
      if (json['submission_updated_at'] != null) {
        submissionUpdatedAt =
            DateTime.parse(json['submission_updated_at'].toString()).toLocal();
      }
    } catch (_) {}

    /// Tambahan
    final String? link = json['link'];
    final String? attachment = json['attachment'];
    final String? embed = json['embed'];

    /// Status & warna
    final bool isLate =
        !isSubmitted && dueDate != null && dueDate.isBefore(now);

    String status;
    Color color;

    if (isSubmitted) {
      status = pointDisplay != "-" ? 'Sudah Dinilai' : 'Sudah Mengumpulkan';
      color = Colors.green.shade600;
    } else if (isLate) {
      status = 'Terlambat';
      color = Colors.orange.shade800;
    } else {
      status = 'Belum Mengerjakan';
      color = Colors.red.shade700;
    }

    return AssignmentModel(
      id: json['id'] ?? 0,
      mapelId: json['mapel_id'] ?? 0,
      subjectName: json['subject_name'] ?? 'Mapel Tidak Diketahui',
      title: json['title'] ?? '-',
      description: json['description'],
      dueDate: dueDate,
      taskId: json['task_id'] is int
          ? json['task_id'] as int
          : int.tryParse('${json['task_id'] ?? ''}'),
      isSubmitted: isSubmitted,
      status: status,
      statusColor: color,
      classroomId: json['classroom_id'] as int?,
      point: pointDisplay,
      studentDescription: json['student_description']?.toString(),
      studentAttachment: studentAttachment,
      submittedAt: submittedAt,
      submissionUpdatedAt: submissionUpdatedAt,
      link: link,
      attachment: attachment,
      embed: embed,
    );
  }

  bool get isLate =>
      !isSubmitted && dueDate != null && dueDate!.isBefore(DateTime.now());

  bool get canEditSubmission =>
      isSubmitted && (dueDate == null || dueDate!.isAfter(DateTime.now()));
}
