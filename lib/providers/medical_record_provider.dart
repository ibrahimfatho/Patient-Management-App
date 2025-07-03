import 'package:flutter/material.dart';
import '../models/medical_record_model.dart';
import '../services/firebase_medical_record_service.dart';

class MedicalRecordProvider with ChangeNotifier {
  final FirebaseMedicalRecordService _medicalRecordService = FirebaseMedicalRecordService();
  List<MedicalRecord> _medicalRecords = [];
  bool _isLoading = false;
  String? _error;

  List<MedicalRecord> get medicalRecords => [..._medicalRecords];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPatientMedicalRecords(String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicalRecords = await _medicalRecordService.getMedicalRecordsByPatientId(patientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedicalRecord(MedicalRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _medicalRecordService.addMedicalRecord(record);
      if (id != null) {
        await fetchPatientMedicalRecords(record.patientId);
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

  Future<bool> updateMedicalRecord(MedicalRecord record) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _medicalRecordService.updateMedicalRecord(record);
      if (success) {
        await fetchPatientMedicalRecords(record.patientId);
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

  Future<bool> deleteMedicalRecord(String id, String patientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _medicalRecordService.deleteMedicalRecord(id);
      if (success) {
        await fetchPatientMedicalRecords(patientId);
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
