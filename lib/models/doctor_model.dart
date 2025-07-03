class Doctor {
  final String? id;
  final String name;
  final String specialization;
  final String phoneNumber;
  final String email;
  final String userId;

  Doctor({
    this.id,
    required this.name,
    required this.specialization,
    required this.phoneNumber,
    required this.email,
    required this.userId,
  });

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'] is int ? (map['id'] as int).toString() : map['id'] as String?,
      name: map['name'] ?? '',
      specialization: map['specialization'] ?? '',
      phoneNumber: map['phone'] ?? map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'phoneNumber': phoneNumber,
      'email': email,
      'userId': userId,
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? specialization,
    String? phoneNumber,
    String? email,
    String? userId,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      userId: userId ?? this.userId,
    );
  }
}
