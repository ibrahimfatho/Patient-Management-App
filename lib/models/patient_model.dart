class Patient {
  final String? id;
  final String name;
  final String phone;
  final String address;
  final String gender;
  final String dateOfBirth;
  final String bloodType;
  final String? medicalHistory;
  final String? allergies;
  final String? notes;
  final String createdAt;
  final String? patientNumber; // رقم المريض
  
  // Detailed medical history fields
  final String? chronicDiseases; // الأمراض المزمنة والحادة
  final String? surgicalHistory; // العمليات الجراحية السابقة
  final String? currentMedications; // الأدوية الحالية
  final String? familyMedicalHistory; // التاريخ العائلي للأمراض
  final String? socialHistory; // التاريخ الاجتماعي
  final String? immunizations; // اللقاحات
  final String? gynecologicalHistory; // التاريخ النسائي (للنساء)

  Patient({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.gender,
    required this.dateOfBirth,
    required this.bloodType,
    this.medicalHistory,
    this.allergies,
    this.notes,
    required this.createdAt,
    this.patientNumber,
    this.chronicDiseases,
    this.surgicalHistory,
    this.currentMedications,
    this.familyMedicalHistory,
    this.socialHistory,
    this.immunizations,
    this.gynecologicalHistory,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] is int ? (map['id'] as int).toString() : map['id'] as String?,
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      gender: map['gender'],
      dateOfBirth: map['dateOfBirth'],
      bloodType: map['bloodType'],
      medicalHistory: map['medicalHistory'],
      allergies: map['allergies'],
      notes: map['notes'],
      createdAt: map['createdAt'],
      patientNumber: map['patientNumber'],
      chronicDiseases: map['chronicDiseases'],
      surgicalHistory: map['surgicalHistory'],
      currentMedications: map['currentMedications'],
      familyMedicalHistory: map['familyMedicalHistory'],
      socialHistory: map['socialHistory'],
      immunizations: map['immunizations'],
      gynecologicalHistory: map['gynecologicalHistory'],
    );
  }

  Map<String, dynamic> toMap() {
    // We exclude the id field as Firestore will generate/manage document IDs
    return {
      // 'id' field is intentionally excluded as it should be the Firestore document ID
      'name': name,
      'phone': phone,
      'address': address,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'bloodType': bloodType,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'notes': notes,
      'createdAt': createdAt,
      'patientNumber': patientNumber,
      'chronicDiseases': chronicDiseases,
      'surgicalHistory': surgicalHistory,
      'currentMedications': currentMedications,
      'familyMedicalHistory': familyMedicalHistory,
      'socialHistory': socialHistory,
      'immunizations': immunizations,
      'gynecologicalHistory': gynecologicalHistory,
    };
  }

  Patient copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? gender,
    String? dateOfBirth,
    String? bloodType,
    String? medicalHistory,
    String? allergies,
    String? notes,
    String? createdAt,
    String? chronicDiseases,
    String? surgicalHistory,
    String? currentMedications,
    String? familyMedicalHistory,
    String? socialHistory,
    String? immunizations,
    String? gynecologicalHistory,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      currentMedications: currentMedications ?? this.currentMedications,
      familyMedicalHistory: familyMedicalHistory ?? this.familyMedicalHistory,
      socialHistory: socialHistory ?? this.socialHistory,
      immunizations: immunizations ?? this.immunizations,
      gynecologicalHistory: gynecologicalHistory ?? this.gynecologicalHistory,
    );
  }
}
