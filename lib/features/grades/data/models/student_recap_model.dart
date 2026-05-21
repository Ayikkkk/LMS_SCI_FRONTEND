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
      nis: json['nis']?.toString() ?? '-',
      name: json['name']?.toString() ?? '-',
      kelas: json['kelas']?.toString() ?? '-',
    );
  }
}
