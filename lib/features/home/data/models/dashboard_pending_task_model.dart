class PendingTaskModel {
  final int id;
  final String title;
  final DateTime dueDate;

  PendingTaskModel({
    required this.id,
    required this.title,
    required this.dueDate,
  });

  factory PendingTaskModel.fromJson(Map<String, dynamic> json) {
    return PendingTaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '-',
      dueDate: DateTime.parse(json['due_date']).toLocal(),
    );
  }

  bool get isUrgent => dueDate.isBefore(DateTime.now().add(const Duration(days: 1)));
}
