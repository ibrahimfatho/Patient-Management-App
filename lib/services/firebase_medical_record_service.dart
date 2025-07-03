import '../models/medical_record_model.dart';
import 'firebase_service.dart';

class FirebaseMedicalRecordService {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Get all medical records
  Future<List<MedicalRecord>> getAllMedicalRecords() async {
    try {
      final querySnapshot = await _firebaseService.medicalRecordsCollection.get();
      
      return querySnapshot.docs.map((doc) {
        return MedicalRecord.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting all medical records: $e');
      return [];
    }
  }
  
  // Get medical record by ID
  Future<MedicalRecord?> getMedicalRecordById(String recordId) async {
    try {
      final docSnapshot = await _firebaseService.medicalRecordsCollection.doc(recordId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return MedicalRecord.fromMap({
        'id': docSnapshot.id,
        ...docSnapshot.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting medical record by ID: $e');
      return null;
    }
  }
  
  // Get medical records by patient ID
  Future<List<MedicalRecord>> getMedicalRecordsByPatientId(String patientId) async {
    try {
      final querySnapshot = await _firebaseService.medicalRecordsCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return MedicalRecord.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting medical records by patient ID: $e');
      return [];
    }
  }
  
  // Get medical records by doctor ID
  Future<List<MedicalRecord>> getMedicalRecordsByDoctorId(String doctorId) async {
    try {
      final querySnapshot = await _firebaseService.medicalRecordsCollection
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('date', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        return MedicalRecord.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting medical records by doctor ID: $e');
      return [];
    }
  }
  
  // Add new medical record
  Future<String?> addMedicalRecord(MedicalRecord record) async {
    try {
      // Add medical record to Firestore
      final docRef = await _firebaseService.medicalRecordsCollection.add(record.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding medical record: $e');
      return null;
    }
  }
  
  // Update medical record
  Future<bool> updateMedicalRecord(MedicalRecord record) async {
    try {
      if (record.id == null) {
        throw Exception('Medical record ID cannot be null');
      }
      
      await _firebaseService.medicalRecordsCollection.doc(record.id.toString()).update(record.toMap());
      return true;
    } catch (e) {
      print('Error updating medical record: $e');
      return false;
    }
  }
  
  // Delete medical record
  Future<bool> deleteMedicalRecord(String recordId) async {
    try {
      await _firebaseService.medicalRecordsCollection.doc(recordId).delete();
      return true;
    } catch (e) {
      print('Error deleting medical record: $e');
      return false;
    }
  }
  
  // Get medical records with patient and doctor information
  Future<List<MedicalRecord>> getMedicalRecordsWithDetails() async {
    try {
      final querySnapshot = await _firebaseService.medicalRecordsCollection
          .orderBy('date', descending: true)
          .get();
      
      List<MedicalRecord> records = [];
      
      for (var doc in querySnapshot.docs) {
        final recordData = doc.data() as Map<String, dynamic>;
        
        // Get patient name
        String? patientName;
        if (recordData['patientId'] != null) {
          final patientDoc = await _firebaseService.patientsCollection
              .doc(recordData['patientId'].toString())
              .get();
          
          if (patientDoc.exists) {
            patientName = (patientDoc.data() as Map<String, dynamic>)['name'];
          }
        }
        
        // Get doctor name
        String? doctorName;
        if (recordData['doctorId'] != null) {
          final doctorDoc = await _firebaseService.usersCollection
              .doc(recordData['doctorId'].toString())
              .get();
          
          if (doctorDoc.exists) {
            doctorName = (doctorDoc.data() as Map<String, dynamic>)['name'];
          }
        }
        
        // Create medical record with additional information
        records.add(MedicalRecord.fromMap({
          'id': doc.id,
          ...recordData,
          'patientName': patientName,
          'doctorName': doctorName,
        }));
      }
      
      return records;
    } catch (e) {
      print('Error getting medical records with details: $e');
      return [];
    }
  }
}
