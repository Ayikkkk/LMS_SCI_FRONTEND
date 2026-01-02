class RecapSubjectModel {
  final String mapel;
  final List<String> headers;
  final Map<String, dynamic> scores;

  RecapSubjectModel({
    required this.mapel,
    required this.headers,
    required this.scores,
  });

  factory RecapSubjectModel.fromJson(Map<String, dynamic> json) {
    final headers = List<String>.from(json['headers'] ?? []);

    final scores = <String, dynamic>{};
    final rawScores = json['scores'] as Map<String, dynamic>? ?? {};

    for (final entry in rawScores.entries) {
      scores[entry.key] = entry.value;
    }

    return RecapSubjectModel(
      mapel: json['mapel'] as String,
      headers: headers,
      scores: scores,
    );
  }

  /// Helper aman untuk UI
  String displayScore(String header) {
    final value = scores[header];
    return value == null ? '-' : value.toString();
  }
}
