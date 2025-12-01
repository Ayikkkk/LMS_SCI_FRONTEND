import 'guru_model.dart';

class StudentModel {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? photoUrl;

  final String? nis;
  final int? classRoomId;
  final String? className;

  final int? userId;
  final int? serialId;

  final Guru? guru;

  StudentModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.photoUrl,
    this.nis,
    this.classRoomId,
    this.className,
    this.userId,
    this.serialId,
    this.guru,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? "-",
      username: json['username'] ?? "-",
      email: json['email'],
      photoUrl: json['photo'],

      /// JSON API: "nis"
      nis: json['nis']?.toString(),

      classRoomId: json['classroom_id'],

      /// classroom safe-check
      className: json['classroom'] != null
          ? json['classroom']['name']
          : null,

      userId: json['user_id'],
      serialId: json['serial_id'],

      /// guru dari JSON
      guru: json['guru'] != null ? Guru.fromJson(json['guru']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "username": username,
      "email": email,
      "photo": photoUrl,
      "nis": nis,
      "classroom_id": classRoomId,
      "user_id": userId,
      "serial_id": serialId,
    };
  }

  StudentModel copyWith({
    String? name,
    String? photoUrl,
    String? className,
    Guru? guru,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      username: username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      nis: nis,
      classRoomId: classRoomId,
      className: className ?? this.className,
      userId: userId,
      serialId: serialId,
      guru: guru ?? this.guru,
    );
  }
}
