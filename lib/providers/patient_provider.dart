import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../services/firebase_patient_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_service.dart';

class PatientProvider with ChangeNotifier {
  final FirebasePatientService _patientService = FirebasePatientService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseService _firebaseService = FirebaseService();
  List<Patient> _patients = [];
  List<Patient> _allPatients = []; // Store all patients for filtering
  bool _isLoading = false;
  String? _error;
  Patient? _selectedPatient;

  List<Patient> get patients => [..._patients];
  List<Patient> get allPatients => [..._allPatients];
  bool get isLoading => _isLoading;
  String? get error => _error;
  Patient? get selectedPatient => _selectedPatient;

  Future<void> fetchPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _patientService.getAllPatients();
      _allPatients = [..._patients]; // Store a copy of all patients
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPatientsForDoctor(String doctorId) async {
    if (doctorId.isEmpty) {
      _error = 'Doctor ID cannot be empty.';
      _patients = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Assuming getPatientsForDoctor exists in _patientService and returns List<Patient>
      _patients = await _patientService.getPatientsForDoctor(doctorId);
      // Optionally, update _allPatients if this fetch should replace the main list
      // _allPatients = [..._patients]; 
    } catch (e) {
      _error = e.toString();
      _patients = []; // Clear patients list on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPatients(String query) async {
    if (query.isEmpty) {
      await fetchPatients();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _patients = await _patientService.searchPatients(query);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get patient by exact phone number (for patient login)
  Future<Patient?> getPatientByPhone(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final patient = await _patientService.getPatientByPhone(phone);
      if (patient != null) {
        _patients = [patient];
      } else {
        _patients = [];
      }
      return patient;
    } catch (e) {
      _error = e.toString();
      _patients = [];
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPatient(Patient patient, {
    required String adminAuthIdentifier, // This can be email or username
    required String adminPassword,
    required String originalAdminAuthUserUid,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? authUserId;
      
      // 1. First, add the patient to Firestore to get a patientId
      final patientId = await _patientService.addPatient(patient);
      if (patientId == null) {
        print('Failed to create patient document');
        _error = 'Failed to create patient document';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      print('Successfully created patient with ID: $patientId');
      
      // 2. Create Firebase Auth account for the patient
      try {
        // Format email using phone number
        final email = '${patient.phone}@patient.com';
        
        // Create user in Firebase Auth with default password '123456'
        final authResult = await _firebaseService.auth.createUserWithEmailAndPassword(
          email: email,
          password: '123456', // Default password for patients
        );
        
        // Get the Firebase Auth UID
        authUserId = authResult.user?.uid;
        print('Successfully created auth account for patient: ${patient.name} with ID: $authUserId');
      } catch (authError) {
        // If the user already exists, don't treat it as an error
        if (authError is FirebaseAuthException && authError.code == 'email-already-in-use') {
          print('Auth account already exists for patient: ${patient.phone}');
          
          // Try to sign in to get the user ID
          try {
            final email = '${patient.phone}@patient.com';
            final authResult = await _firebaseService.auth.signInWithEmailAndPassword(
              email: email,
              password: '123456',
            );
            authUserId = authResult.user?.uid;
          } catch (signInError) {
            print('Could not sign in to get patient user ID: $signInError');
          }
        } else {
          print('Warning: Error creating patient auth account: $authError');
        }
      }
      
      // 3. Create a user entry in the users collection with the patientId
      if (authUserId != null) {
        try {
          // Create user document with the same ID as the auth account
          // IMPORTANT: We're using the patientId from the created patient document
          final patientEmail = '${patient.phone}@patient.com'; // Construct patient email
          await _firebaseService.usersCollection.doc(authUserId).set({
            'username': patient.phone,
            'email': patientEmail, // Store the constructed email
            'password': '123456', // Default password
            'role': 'patient',
            'name': patient.name,
            'userId': authUserId,
            'patientId': patientId, // Link to the patient document using the generated patientId
            'createdAt': DateTime.now().toIso8601String(),
          });
          
          print('Successfully created user record for patient: ${patient.name} with patientId: $patientId');
          
          // 4. Update the patient document with the userId for bidirectional linking
          try {
            await _firebaseService.patientsCollection.doc(patientId).update({
              'userId': authUserId
            });
            print('Updated patient document with userId: $authUserId');
          } catch (e) {
            print('Warning: Could not update patient with userId: $e');
          }
        } catch (userError) {
          print('Warning: Created patient but user record creation failed: $userError');
          // Continue - we don't want to block patient creation if user record fails
        }
      }
      
      // Admin Re-authentication Logic
      if (FirebaseAuth.instance.currentUser?.uid != originalAdminAuthUserUid) {
        print('Admin session changed to new patient. Attempting to re-authenticate admin: $adminAuthIdentifier');
        try {
          await _authService.signInWithEmailAndPassword(adminAuthIdentifier, adminPassword);
          if (FirebaseAuth.instance.currentUser?.uid == originalAdminAuthUserUid) {
            print('Admin re-authenticated successfully: $adminAuthIdentifier');
          } else {
            print('CRITICAL: Admin re-authentication attempt finished, but current user is NOT the original admin. Current user: ${FirebaseAuth.instance.currentUser?.uid}');
            _error = 'Patient created, but critical error restoring admin session. Please re-login.';
            // Do not return true here as the admin session is compromised.
            // Consider how to alert the user more forcefully.
          }
        } catch (reAuthError) {
          print('Error re-authenticating admin $adminAuthIdentifier: $reAuthError');
          _error = 'Patient created, but failed to restore admin session: $reAuthError. Please re-login.';
          // Patient creation was successful, but admin session is lost.
          // Still, fetch patients and notify, but the error message is important.
        }
      } else {
        print('Admin session did not change, no re-authentication needed.');
      }

      await fetchPatients();
      // If _error was set by re-auth, it will be shown. Otherwise, it's a success.
      // If re-auth failed critically, we might have already returned false or thrown.
      _isLoading = false;
      notifyListeners();
      return _error == null || !_error!.contains("CRITICAL"); // Return true if no error or non-critical re-auth error
    } catch (e) {
      _error = e.toString();
      print('Error in addPatient: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePatient(Patient patient) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _patientService.updatePatient(patient);
      if (success) {
        await fetchPatients();
        if (_selectedPatient?.id == patient.id) {
          _selectedPatient = patient;
        }
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

  Future<bool> deletePatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _patientService.deletePatient(id);
      if (success) {
        await fetchPatients();
        if (_selectedPatient?.id == id) {
          _selectedPatient = null;
        }
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

  Future<void> selectPatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedPatient = await _patientService.getPatientById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedPatient() {
    _selectedPatient = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Get patient by ID
  Future<Patient?> getPatientById(String id) async {
    try {
      return await _patientService.getPatientById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  // Get all patients
  Future<List<Patient>> getAllPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final patients = await _patientService.getAllPatients();
      _isLoading = false;
      notifyListeners();
      return patients;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  // Set filtered patients list
  void setFilteredPatients(List<Patient> filteredPatients) {
    _patients = filteredPatients;
    notifyListeners();
  }
  
  // Fetch patients for a specific doctor - only patients that have appointments with this doctor
  Future<void> fetchDoctorPatients(String doctorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First, get all appointments for this doctor
      final appointments = await _firebaseService.appointmentsCollection
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      // Extract unique patient IDs from these appointments
      final patientIds = appointments.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return data?['patientId'] as String?;
          })
          .where((id) => id != null)
          .toSet();
      
      print('Doctor $doctorId has appointments with ${patientIds.length} patients');
      
      if (patientIds.isEmpty) {
        // No appointments found for this doctor
        _patients = [];
        _allPatients = [];
      } else {
        // Fetch all patients
        final allPatients = await _patientService.getAllPatients();
        
        // Filter to only include patients with appointments
        _patients = allPatients.where((patient) => patientIds.contains(patient.id)).toList();
        _allPatients = [..._patients]; // Store a copy of all patients
        
        print('Filtered to ${_patients.length} patients for doctor $doctorId');
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching doctor patients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
