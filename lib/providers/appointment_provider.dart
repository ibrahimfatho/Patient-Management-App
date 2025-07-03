import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/firebase_appointment_service.dart';

class AppointmentProvider with ChangeNotifier {
  final FirebaseAppointmentService _appointmentService = FirebaseAppointmentService();
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<Appointment> get appointments => [..._appointments];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _appointmentService.getAllAppointments();
      await _autoCancelOverdueAppointments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDoctorAppointments(String doctorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _appointmentService.getAppointmentsByDoctorId(doctorId);
      await _autoCancelOverdueAppointments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchPatientAppointments(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _appointments = await _appointmentService.getAppointmentsByPatientId(patientId);
      await _autoCancelOverdueAppointments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _autoCancelOverdueAppointments() async {
    final now = DateTime.now();
    List<Appointment> appointmentsToUpdate = [];

    for (var appointment in _appointments) {
      if (appointment.status == 'scheduled') {
        try {
          final appointmentDateTime = DateTime.parse('${appointment.date} ${appointment.time}');
          if (now.isAfter(appointmentDateTime.add(const Duration(hours: 1)))) {
            appointmentsToUpdate.add(appointment.copyWith(status: 'cancelled'));
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    if (appointmentsToUpdate.isNotEmpty) {
      for (var appointment in appointmentsToUpdate) {
        await _appointmentService.updateAppointment(appointment);
      }
      // Re-fetch the list to ensure UI is consistent
      _appointments = await _appointmentService.getAllAppointments(); 
    }
  }

  Future<bool> addAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _appointmentService.addAppointment(appointment);
      if (id != null) {
        await fetchAllAppointments();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAppointment(Appointment appointment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _appointmentService.updateAppointment(appointment);
      if (success) {
        await fetchAllAppointments();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _appointmentService.deleteAppointment(id);
      if (success) {
        await fetchAllAppointments();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
