import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class FirebaseAppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'appointments';

  // Get all appointments
  Future<List<Appointment>> getAllAppointments() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id; // Add the document ID to the map
        return Appointment.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching appointments: $e');
      throw e;
    }
  }

  // Get appointments by doctor ID
  Future<List<Appointment>> getAppointmentsByDoctorId(String doctorId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('doctorId', isEqualTo: doctorId)
          .get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id; // Add the document ID to the map
        return Appointment.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching doctor appointments: $e');
      throw e;
    }
  }

  // Get appointments by patient ID
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('patientId', isEqualTo: patientId)
          .get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id; // Add the document ID to the map
        return Appointment.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching patient appointments: $e');
      throw e;
    }
  }

  // Add a new appointment
  Future<String?> addAppointment(Appointment appointment) async {
    try {
      final docRef = await _firestore.collection(_collection).add(appointment.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding appointment: $e');
      throw e;
    }
  }

  // Update an existing appointment
  Future<bool> updateAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(appointment.id)
          .update(appointment.toMap());
      return true;
    } catch (e) {
      print('Error updating appointment: $e');
      throw e;
    }
  }

  // Delete an appointment
  Future<bool> deleteAppointment(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting appointment: $e');
      throw e;
    }
  }
}
