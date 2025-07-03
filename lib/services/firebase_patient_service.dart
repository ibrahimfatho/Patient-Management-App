import '../models/patient_model.dart';
import 'firebase_service.dart';

class FirebasePatientService {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Get all patients
  Future<List<Patient>> getAllPatients() async {
    try {
      final querySnapshot = await _firebaseService.patientsCollection.get();
      
      return querySnapshot.docs.map((doc) {
        return Patient.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      print('Error getting all patients: $e');
      return [];
    }
  }
  
  // Get patient by ID
  Future<Patient?> getPatientById(String patientId) async {
    try {
      final docSnapshot = await _firebaseService.patientsCollection.doc(patientId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return Patient.fromMap({
        'id': docSnapshot.id,
        ...docSnapshot.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting patient by ID: $e');
      return null;
    }
  }
  
  // Get patient by phone number
  Future<Patient?> getPatientByPhone(String phone) async {
    try {
      final querySnapshot = await _firebaseService.patientsCollection
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return Patient.fromMap({
        'id': querySnapshot.docs.first.id,
        ...querySnapshot.docs.first.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting patient by phone: $e');
      return null;
    }
  }
  
  // Add new patient
  Future<String?> addPatient(Patient patient) async {
    try {
      // Check if patient with same phone already exists
      final existingPatient = await getPatientByPhone(patient.phone);
      if (existingPatient != null) {
        throw Exception('Patient with this phone number already exists');
      }
      
      // Create a map from the patient object (id is excluded in toMap)
      final patientData = patient.toMap();
      
      // Add patient to Firestore
      final docRef = await _firebaseService.patientsCollection.add(patientData);
      final patientId = docRef.id;
      
      // Update the patient in Firestore with its ID to ensure consistency
      await _firebaseService.patientsCollection.doc(patientId).update({
        'patientId': patientId, // Add patientId field for easier querying
      });
      
      return patientId;
    } catch (e) {
      print('Error adding patient: $e');
      return null;
    }
  }
  
  // Update patient
  Future<bool> updatePatient(Patient patient) async {
    try {
      if (patient.id == null) {
        throw Exception('Patient ID cannot be null');
      }
      
      final patientId = patient.id.toString();
      final patientData = patient.toMap();
      
      // Ensure patientId field is set for consistency
      patientData['patientId'] = patientId;
      
      // Update the patient document in Firestore
      await _firebaseService.patientsCollection.doc(patientId).update(patientData);
      return true;
    } catch (e) {
      print('Error updating patient: $e');
      return false;
    }
  }
  
  // Delete patient and all related records
  Future<bool> deletePatient(String patientId) async {
    try {
      // Validate the patientId
      if (patientId.isEmpty) {
        print('Error: Attempted to delete patient with empty ID');
        return false;
      }

      // Use a batch to delete multiple documents atomically
      final batch = _firebaseService.firestore.batch();
      
      // Reference to the patient document
      final patientRef = _firebaseService.patientsCollection.doc(patientId);
      
      // 1. First, get all appointments for this patient
      final appointmentsSnapshot = await _firebaseService.appointmentsCollection
          .where('patientId', isEqualTo: patientId)
          .get();
      
      // Add all appointment deletions to the batch
      for (var doc in appointmentsSnapshot.docs) {
        batch.delete(doc.reference);
        print('Queued appointment ${doc.id} for deletion');
      }
      
      // 2. Get all medical records for this patient
      final medicalRecordsSnapshot = await _firebaseService.medicalRecordsCollection
          .where('patientId', isEqualTo: patientId)
          .get();
      
      // Add all medical record deletions to the batch
      for (var doc in medicalRecordsSnapshot.docs) {
        batch.delete(doc.reference);
        print('Queued medical record ${doc.id} for deletion');
      }
      
      // 3. Finally, delete the patient document
      batch.delete(patientRef);
      print('Queued patient $patientId for deletion');
      
      // 4. Find and delete the associated user document from the /users collection
      // The link is User.patientId == patientId (the ID of the patient document)
      final usersSnapshot = await _firebaseService.usersCollection
          .where('patientId', isEqualTo: patientId)
          .limit(1) // Assuming one user per patient record
          .get();

      if (usersSnapshot.docs.isNotEmpty) {
        final userDoc = usersSnapshot.docs.first;
        batch.delete(userDoc.reference);
        print('Queued user ${userDoc.id} (associated with patient $patientId) for deletion from /users collection.');
        // IMPORTANT: The actual Firebase Auth account for user ${userDoc.id} needs to be deleted separately (e.g., via a Cloud Function).
        final userData = userDoc.data() as Map<String, dynamic>?;
        print('IMPORTANT: Firebase Auth account for user ${userDoc.id} (email: ${userData?['email'] ?? 'N/A'}) needs to be deleted separately.');
      } else {
        print('No associated user found in /users collection for patient $patientId.');
      }

      // Commit the batch
      await batch.commit();
      print('Successfully deleted patient $patientId and all related records (including associated user document if found).');
      
      return true;
    } catch (e) {
      print('Error deleting patient: $e');
      return false;
    }
  }
  
  // Get patients for a specific doctor
  Future<List<Patient>> getPatientsForDoctor(String doctorId) async {
    if (doctorId.isEmpty) {
      print('Error: doctorId cannot be empty when fetching patients for a doctor.');
      return [];
    }
    try {
      // 1. Get all appointments for this doctor
      final appointmentsSnapshot = await _firebaseService.appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .get();

      if (appointmentsSnapshot.docs.isEmpty) {
        print('No appointments found for doctor $doctorId.');
        return [];
      }

      // 2. Extract unique patient IDs from these appointments
      final patientIds = appointmentsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?; // Ensure data is treated as potentially null or cast safely
            return data?['patientId'] as String?;
          })
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>() // Explicitly cast to Set<String> after filtering nulls
          .toSet(); // Use a Set to ensure uniqueness

      if (patientIds.isEmpty) {
        print('No valid patient IDs found in appointments for doctor $doctorId.');
        return [];
      }

      // 3. Fetch patient details for each unique patient ID
      final List<Patient> patients = [];
      for (String patientId in patientIds) {
        final patient = await getPatientById(patientId);
        if (patient != null) {
          patients.add(patient);
        }
      }
      print('Fetched ${patients.length} patients for doctor $doctorId.');
      return patients;
    } catch (e) {
      print('Error getting patients for doctor $doctorId: $e');
      return [];
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients(String query) async {
    try {
      // Firebase doesn't support direct text search, so we'll fetch all and filter
      // For a production app, consider using Algolia or other search service
      final querySnapshot = await _firebaseService.patientsCollection.get();
      
      final patients = querySnapshot.docs.map((doc) {
        return Patient.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
      
      // Filter patients based on query
      if (query.isEmpty) {
        return patients;
      }
      
      final lowercaseQuery = query.toLowerCase();
      return patients.where((patient) {
        return patient.name.toLowerCase().contains(lowercaseQuery) ||
               patient.phone.toLowerCase().contains(lowercaseQuery) ||
               (patient.patientNumber?.toLowerCase().contains(lowercaseQuery) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching patients: $e');
      return [];
    }
  }
}
