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
    return RecapScoreModel(
      student: StudentRecapModel.fromJson(json['student']),
      subjects: (json['rows'] as List<dynamic>)
          .map((e) => RecapSubjectModel.fromJson(e))
          .toList(),
    );
  }
}
