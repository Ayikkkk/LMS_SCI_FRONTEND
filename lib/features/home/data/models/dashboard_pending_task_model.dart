class PendingTaskModel {
  final int id;
  final String title;
  final DateTime? dueDate; // nullable — tugas mungkin tidak punya deadline
  final String? subjectName;

  PendingTaskModel({
    required this.id,
    required this.title,
    this.dueDate,
    this.subjectName,
  });

  factory PendingTaskModel.fromJson(Map<String, dynamic> json) {
    return PendingTaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '-',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date']).toLocal()
          : null,
      subjectName: json['subject_name'] as String?,
    );
  }

  bool get isUrgent {
    if (dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now().add(const Duration(days: 1)));
  }

  /// Sisa waktu dalam format singkat
  String get deadlineLabel {
    if (dueDate == null) return 'Tanpa batas waktu';
    final now = DateTime.now();
    final diff = dueDate!.difference(now);
    if (diff.isNegative) return 'Terlambat';
    if (diff.inHours < 1) return 'Kurang dari 1 jam';
    if (diff.inHours < 24) return '${diff.inHours} jam lagi';
    if (diff.inDays == 1) return 'Besok';
    return '${diff.inDays} hari lagi';
  }
}
