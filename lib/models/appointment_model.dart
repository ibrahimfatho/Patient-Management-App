class Appointment {
  final String? id;
  final String patientId;
  final String doctorId;
  final String date;
  final String time;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? notes;
  final String? patientName; // For joining with patient data
  final String? doctorName; // For joining with doctor data

  Appointment({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
    this.patientName,
    this.doctorName,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id']?.toString(),
      patientId: map['patientId']?.toString() ?? '',
      doctorId: map['doctorId']?.toString() ?? '',
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      status: map['status'] as String? ?? 'scheduled',
      notes: map['notes'] as String?,
      patientName: map['patientName'] as String?,
      doctorName: map['doctorName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    // We exclude the id field as Firestore will generate/manage document IDs
    return {
      // 'id' field is intentionally excluded as it should be the Firestore document ID
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date,
      'time': time,
      'status': status,
      'notes': notes,
      // Always include patient and doctor names for display purposes
      'patientName': patientName ?? '',
      'doctorName': doctorName ?? '',
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? date,
    String? time,
    String? status,
    String? notes,
    String? patientName,
    String? doctorName,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
    );
  }
}
