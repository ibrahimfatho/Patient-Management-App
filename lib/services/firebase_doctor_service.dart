import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';
import 'firebase_service.dart';

class FirebaseDoctorService {
  final FirebaseService _firebaseService = FirebaseService();

  // Get reference to doctors collection
  CollectionReference get doctorsCollection => _firebaseService.doctorsCollection;

  // Get all doctors
  Future<List<Doctor>> getAllDoctors() async {
    try {
      final querySnapshot = await doctorsCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Doctor.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting all doctors: $e');
      return [];
    }
  }

  // Get doctor by ID
  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      final docSnapshot = await doctorsCollection.doc(doctorId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return Doctor.fromMap({
          'id': docSnapshot.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error getting doctor by ID: $e');
      return null;
    }
  }

  // Add a new doctor
  Future<String?> addDoctor(Doctor doctor) async {
    try {
      final docRef = await doctorsCollection.add({
        'name': doctor.name,
        'specialization': doctor.specialization,
        'phoneNumber': doctor.phoneNumber,
        'email': doctor.email,
        'userId': doctor.userId,
      });
      return docRef.id;
    } catch (e) {
      print('Error adding doctor: $e');
      return null;
    }
  }

  // Update an existing doctor
  Future<bool> updateDoctor(Doctor doctor) async {
    try {
      await doctorsCollection.doc(doctor.id.toString()).update({
        'name': doctor.name,
        'specialization': doctor.specialization,
        'phoneNumber': doctor.phoneNumber,
        'email': doctor.email,
        'userId': doctor.userId,
      });
      return true;
    } catch (e) {
      print('Error updating doctor: $e');
      return false;
    }
  }

  // Delete a doctor
  Future<bool> deleteDoctor(String doctorId) async {
    try {
      await doctorsCollection.doc(doctorId).delete();
      return true;
    } catch (e) {
      print('Error deleting doctor: $e');
      return false;
    }
  }

  // Get doctors by user ID
  Future<List<Doctor>> getDoctorsByUserId(String userId) async {
    try {
      final querySnapshot = await doctorsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Doctor.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting doctors by user ID: $e');
      return [];
    }
  }
}
