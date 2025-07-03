class MedicalRecord {
  final String? id;
  final String patientId;
  final String doctorId;
  final String date;
  final String diagnosis;
  final String prescription;
  final String? notes;
  final String? patientName; // For joining with patient data
  final String? doctorName; // For joining with doctor data

  MedicalRecord({
    this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.diagnosis,
    required this.prescription,
    this.notes,
    this.patientName,
    this.doctorName,
  });

  factory MedicalRecord.fromMap(Map<String, dynamic> map) {
    return MedicalRecord(
      id: map['id'] is int ? (map['id'] as int).toString() : map['id'] as String?,
      patientId: map['patientId'] is int ? (map['patientId'] as int).toString() : map['patientId'] as String,
      doctorId: map['doctorId'] is int ? (map['doctorId'] as int).toString() : map['doctorId'] as String,
      date: map['date'] as String,
      diagnosis: map['diagnosis'] as String,
      prescription: map['prescription'] as String,
      notes: map['notes'] as String?,
      patientName: map['patientName'] as String?,
      doctorName: map['doctorName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
      'patientName': patientName, // Ensure patientName is also saved if available
      'doctorName': doctorName,   // Add doctorName to be saved
    };
  }
}
