import 'student_recap_model.dart';
import 'recap_subject_model.dart';

class RecapScoreModel {
  final StudentRecapModel student;
  final List<RecapSubjectModel> subjects;

  RecapScoreModel({
    required this.student,
    required this.subjects,
  });

  factory RecapScoreModel.fromJson(Map<String, dynamic> json) {
    final studentData = json['student'] as Map<String, dynamic>? ?? {};
    final rowsData = json['rows'] as List<dynamic>? ?? [];

    return RecapScoreModel(
      student: StudentRecapModel.fromJson(studentData),
      subjects: rowsData
          .whereType<Map<String, dynamic>>()
          .map((e) => RecapSubjectModel.fromJson(e))
          .toList(),
    );
  }
}
