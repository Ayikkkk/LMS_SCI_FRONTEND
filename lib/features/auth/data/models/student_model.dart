class StudentModel {
  final int id;
  final String name;
  final String username;
  final String? email;
  final String? photoUrl;
  final String? absenNumber;
  final int? classRoomId;
  final String? className; // Nama Kelas
  final int? userId;
  final int? serialId;

  StudentModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.photoUrl,
    this.absenNumber,
    this.classRoomId,
    this.className,
    this.userId,
    this.serialId,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    // ---------------------------------------------------------------
    // 💡 LOGIKA PERBAIKAN: Mencari nama kelas dari berbagai sumber
    // ---------------------------------------------------------------
    String? parsedClassName;

    // Skenario 1: Cek jika ada key 'classroom_name' (seperti dari DashboardController)
    if (json.containsKey('classroom_name') && json['classroom_name'] is String) {
        parsedClassName = json['classroom_name'] as String;
    }
    // Skenario 2: Cek jika ada objek relasi 'classroom' (seperti dari Auth Controller yang di-eager load)
    else if (json.containsKey('classroom') && json['classroom'] is Map<String, dynamic>) {
        parsedClassName = (json['classroom'] as Map<String, dynamic>)['name'] as String?;
    }

    // ---------------------------------------------------------------

    return StudentModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Nama Siswa',
      username: json['username'] as String? ?? 'username_siswa',
      email: json['email'] as String?,
      photoUrl: json['photo'] as String?,
      absenNumber: json['absen_number']?.toString(),
      classRoomId: json['class_room_id'] as int?,

      // Menggunakan hasil parsing yang fleksibel
      className: parsedClassName ?? 'Kelas Tidak Dikenal',

      userId: json['user_id'] as int?,
      serialId: json['serial_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    // Note: Kita hanya menyimpan field dasar siswa, tidak perlu menyimpan
    // seluruh objek classroom atau classroom_name di storage.
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'photo': photoUrl,
      'absen_number': absenNumber,
      'class_room_id': classRoomId,
      'user_id': userId,
      'serial_id': serialId,
    };
  }

  StudentModel copyWith({
    String? className,
    String? name,
    String? photoUrl,
  }) {
    return StudentModel(
      id: id,
      name: name ?? this.name,
      username: username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      absenNumber: absenNumber,
      classRoomId: classRoomId,
      className: className ?? this.className,
      userId: userId,
      serialId: serialId,
    );
  }
}