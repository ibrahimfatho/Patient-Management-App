class User {
  final String? id;        // Document ID in Firestore
  final String username;   // Login username
  final String? email;      // User's email address
  final String? password;  // Password (nullable)
  final String role;       // 'admin', 'doctor', or 'patient'
  final String name;       // User's full name
  final String? userId;    // Unique ID (Firebase Auth UID)
  final String? patientId; // Reference to patient document (for patient users)
  final String? doctorId;  // Reference to doctor document (for doctor users)
  final String? createdAt; // Timestamp when user was created
  final String? photoUrl;  // URL to user's profile photo
  final String? specialization; // Doctor's specialization

  User({
    this.id,
    required this.username,
    this.email,
    this.password, // No longer required
    required this.role,
    required this.name,
    this.userId,
    this.patientId,
    this.doctorId,
    this.createdAt,
    this.photoUrl,
    this.specialization,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] is int ? (map['id'] as int).toString() : map['id'] as String?,
      email: map['email'] as String?,
      username: map['username'] as String,
      password: map['password'] as String?, // Handle nullable password
      role: map['role'] as String,
      name: map['name'] as String,
      userId: map['userId'] as String?,
      patientId: map['patientId'] as String?,
      doctorId: map['doctorId'] as String?,
      createdAt: map['createdAt'] as String?,
      photoUrl: map['photoUrl'] as String?,
      specialization: map['specialization'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (password != null) 'password': password, // Only include password if not null
      'role': role,
      'name': name,
      if (userId != null) 'userId': userId,
      if (patientId != null) 'patientId': patientId,
      if (doctorId != null) 'doctorId': doctorId,
      if (createdAt != null) 'createdAt': createdAt,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (specialization != null) 'specialization': specialization,
    };
  }
}
