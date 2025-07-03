import 'package:flutter/material.dart';
import '../models/doctor_model.dart';
import '../services/firebase_doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final FirebaseDoctorService _doctorService = FirebaseDoctorService();
  List<Doctor> _doctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get doctors => [..._doctors];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctors = await _doctorService.getAllDoctors();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDoctorsByUserId(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _doctors = await _doctorService.getDoctorsByUserId(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      return await _doctorService.getDoctorById(doctorId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> addDoctor(Doctor doctor) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _doctorService.addDoctor(doctor);
      if (id != null) {
        await fetchAllDoctors();
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

  Future<bool> updateDoctor(Doctor doctor) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _doctorService.updateDoctor(doctor);
      if (success) {
        await fetchAllDoctors();
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

  Future<bool> deleteDoctor(String doctorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _doctorService.deleteDoctor(doctorId);
      if (success) {
        await fetchAllDoctors();
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
