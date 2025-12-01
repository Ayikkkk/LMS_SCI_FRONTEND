class Guru {
  final int id;
  final String name;
  final String? email;
  final String? phone;

  Guru({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory Guru.fromJson(Map<String, dynamic> json) {
    return Guru(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }
}
