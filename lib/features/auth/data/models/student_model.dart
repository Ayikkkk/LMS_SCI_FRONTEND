import 'guru_model.dart';

class StudentModel {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? photo;
  final String? phone;
  final String? nis;
  final int? absenNumber; // ⬅️ TAMBAHAN
  final int? classroomId;
  final String? className;
  final int? userId;
  final int? serialId;
  final Guru? guru;

  StudentModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.photo,
    this.phone,
    this.nis,
    this.absenNumber,
    this.classroomId,
    this.className,
    this.userId,
    this.serialId,
    this.guru,
  });

  /// Paksa https:// pada URL foto.
  /// Railway dan hosting modern selalu HTTPS dari sisi user,
  /// tapi backend kadang return http:// karena reverse proxy.
  static String? _sanitizePhotoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    return url.replaceFirst('http://', 'https://');
  }

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // unwrap possible { "data": { ... } } wrapper
    final Map<String, dynamic> data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'])
        : Map<String, dynamic>.from(json);

    // ==========================
    // CLASS NAME (multi source)
    // ==========================
    String? parsedClassName;
    if (data['className'] != null) {
      parsedClassName = data['className']?.toString();
    } else if (data['classroom'] is Map && data['classroom']['name'] != null) {
      parsedClassName = data['classroom']['name']?.toString();
    } else if (data['class_name'] != null) {
      parsedClassName = data['class_name']?.toString();
    } else if (data['classroom_name'] != null) {
      parsedClassName = data['classroom_name']?.toString();
    }

    // ==========================
    // CLASSROOM ID (multi source)
    // ==========================
    int? parsedClassroomId;
    if (data['classroom_id'] != null) {
      parsedClassroomId = data['classroom_id'] is int
          ? data['classroom_id'] as int
          : int.tryParse(data['classroom_id'].toString());
    } else if (data['classroomId'] != null) {
      parsedClassroomId = data['classroomId'] is int
          ? data['classroomId'] as int
          : int.tryParse(data['classroomId'].toString());
    }

    // ==========================
    // ABSEN NUMBER (SAFE PARSE)
    // ==========================
    int? parsedAbsen;
    if (data['absen_number'] != null) {
      parsedAbsen = data['absen_number'] is int
          ? data['absen_number'] as int
          : int.tryParse(data['absen_number'].toString());
    } else if (data['absenNumber'] != null) {
      parsedAbsen = data['absenNumber'] is int
          ? data['absenNumber'] as int
          : int.tryParse(data['absenNumber'].toString());
    }

    return StudentModel(
      id: data['id'] is int
          ? data['id'] as int
          : int.tryParse('${data['id'] ?? 0}') ?? 0,
      name: data['name']?.toString() ?? '-',
      username: data['username']?.toString() ?? '-',
      email: data['email']?.toString(),
      photo: _sanitizePhotoUrl(
          data['photo']?.toString() ?? data['photoUrl']?.toString()),
      phone: data['phone']?.toString() ?? data['telephone']?.toString(),
      nis: data['nis']?.toString(),
      absenNumber: parsedAbsen,
      classroomId: parsedClassroomId,
      className: parsedClassName,
      userId: data['user_id'] is int
          ? data['user_id'] as int
          : (data['user_id'] != null
              ? int.tryParse('${data['user_id']}')
              : null),
      serialId: data['serial_id'] is int
          ? data['serial_id'] as int
          : (data['serial_id'] != null
              ? int.tryParse('${data['serial_id']}')
              : null),
      guru: data['guru'] is Map
          ? Guru.fromJson(Map<String, dynamic>.from(data['guru']))
          : null,
    );
  }

  /// ==========================
  /// ONLY FOR PROFILE UPDATE
  /// ==========================
  Map<String, dynamic> toJsonForUpdate() {
    return {
      "name": name,
      "email": email,
      "phone": phone,
    };
  }

  /// ==========================
  /// FULL JSON (READ ONLY USE)
  /// ==========================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'photo': photo,
      'phone': phone,
      'nis': nis,
      'absen_number': absenNumber,
      'classroom_id': classroomId,
      'class_name': className,
      'user_id': userId,
      'serial_id': serialId,
      // guru intentionally omitted
    };
  }

  StudentModel copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    String? photo,
    String? phone,
    String? nis,
    int? absenNumber,
    int? classroomId,
    String? className,
    int? userId,
    int? serialId,
    Guru? guru,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      phone: phone ?? this.phone,
      nis: nis ?? this.nis,
      absenNumber: absenNumber ?? this.absenNumber,
      classroomId: classroomId ?? this.classroomId,
      className: className ?? this.className,
      userId: userId ?? this.userId,
      serialId: serialId ?? this.serialId,
      guru: guru ?? this.guru,
    );
  }
}
