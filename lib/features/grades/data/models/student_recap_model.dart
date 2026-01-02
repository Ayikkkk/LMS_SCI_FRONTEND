class StudentRecapModel {
  final String nis;
  final String name;
  final String kelas;

  StudentRecapModel({
    required this.nis,
    required this.name,
    required this.kelas,
  });

  factory StudentRecapModel.fromJson(Map<String, dynamic> json) {
    return StudentRecapModel(
      nis: json['nis'] as String,
      name: json['name'] as String,
      kelas: json['kelas'] as String,
    );
  }
}
