import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import './chat_notifier.dart';
import './appointment_provider.dart';
import './patient_provider.dart';
import './medical_record_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isDoctor => _currentUser?.role == 'doctor';
  bool get isPatient => _currentUser?.role == 'patient';

  AuthProvider() {
    // Check if user is already logged in
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    // No need to notifyListeners() here if loadCurrentUser will do it or if it's only called from constructor.
    // However, if it could be called at other times, then notifyListeners() might be needed.

    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      // Ensure token is refreshed if needed
      await _authService.refreshIdToken();
      await loadCurrentUser(firebaseUser.uid);
    } else {
      _isLoading = false;
      // notifyListeners(); // Only if _isLoading was true and now false, and something might be listening
    }
  }

  Future<void> loadCurrentUser(String uid) async {
    _isLoading = true;
    _error = null; // Clear previous errors
    notifyListeners();

    try {
      _currentUser = await _authService.getUserById(uid);
      if (_currentUser == null) {
        // This case means a Firebase user exists, but no corresponding document in Firestore /users collection.
        // This could be an error state, or a new user whose Firestore document hasn't been created yet.
        // For splash screen logic, this might mean redirecting to login or an error page.
        _error = 'User details not found in database.';
        // Potentially sign out the Firebase user if their app-level data is missing
        // await _authService.signOut();
      }
    } catch (e) {
      _error = 'Failed to load user data: ${e.toString()}';
      _currentUser = null; // Ensure user is cleared on error
      // Potentially sign out the Firebase user if their app-level data is missing or load failed
      // await _authService.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ensure Firebase token is valid
  Future<bool> ensureValidToken() async {
    try {
      return await _authService.ensureValidToken();
    } catch (e) {
      print('[AuthProvider.ensureValidToken] Error: $e');
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    print(
      '[AuthProvider.login] Attempting login for: $username',
    ); // THIS IS A KEY LOG
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Determine if username is an email or actual username for staff
      // This logic might vary based on your app's specific needs for admin/doctor login
      String loginIdentifier = username;

      // Example: if it's not an email and you expect doctors/admins to login with username
      // you might construct the email like username@doctor.com or username@admin.com
      // For now, assuming 'username' passed to login is what signInWithEmailAndPassword expects
      // or that signInWithEmailAndPassword handles the username-to-email conversion.

      final userCredential = await _authService.signInWithEmailAndPassword(
        loginIdentifier,
        password,
      );
      if (userCredential.user != null) {
        final firebaseUid = userCredential.user!.uid;
        print(
          '[AuthProvider.login] Firebase Auth successful. UID: $firebaseUid. Fetching user details...',
        );
        await loadCurrentUser(firebaseUid);
        print('[AuthProvider.login] User details fetched. _currentUser:');
        print('  ID (Firestore Doc ID): ${_currentUser?.id}');
        print('  UserID (Auth UID): ${_currentUser?.userId}');
        print('  Username: ${_currentUser?.username}');
        print('  Email: ${_currentUser?.email}');
        print('  Role: ${_currentUser?.role}');
        print('  Name: ${_currentUser?.name}');
        print('  Patient ID: ${_currentUser?.patientId}');
        print('  Doctor ID: ${_currentUser?.doctorId}');
        notifyListeners();
        return true;
      } else {
        _error =
            'Login failed: Unable to retrieve user details after authentication.';
        print(
          '[AuthProvider.login] Login error: Firebase user was null after successful auth, or user details not found.',
        );
        notifyListeners(); // Ensure UI updates with the error
        return false;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _error =
          'Login failed: اسم المستخدم/رقم الهاتف  او كلمة المرور غير صحيحة';
      print('[AuthProvider.login] Firebase Auth Exception: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during login.';
      print('[AuthProvider.login] General login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<User?> getUserByPatientId(String patientId) async {
    // No loading state management here as this is a direct fetch, not altering auth state.
    // Errors will be rethrown to be handled by the caller.
    try {
      return await _authService.getUserByPatientId(patientId);
    } catch (e) {
      print('[AuthProvider.getUserByPatientId] Error: $e');
      // Optionally set an error state or just rethrow
      // _error = 'Failed to fetch user by patient ID: ${e.toString()}';
      // notifyListeners();
      rethrow; // Caller should handle this
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _error = null; // Clear error on logout
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For Firebase, we'll just update the password directly
      // In a real app, you might want to re-authenticate the user first
      await _authService.changePassword(
        _currentUser!.id.toString(),
        newPassword,
      );

      // Update the current user object
      _currentUser = User(
        id: _currentUser!.id,
        username: _currentUser!.username,
        password:
            newPassword, // Note: In a real app, you wouldn't store the password in the user object
        role: _currentUser!.role,
        name: _currentUser!.name,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> prefetchUserData(BuildContext context) async {
    if (_currentUser == null) {
      debugPrint(
        '[AuthProvider.prefetchUserData] No current user, skipping prefetch.',
      );
      return;
    }

    debugPrint(
      '[AuthProvider.prefetchUserData] Starting data prefetch for user: ${_currentUser!.id}, role: ${_currentUser!.role}',
    );
    // Optionally, set a specific loading state for prefetching if needed,
    // though individual providers might handle their own loading states.
    // _isLoading = true;
    // notifyListeners();

    try {
      // Common data: Fetch chat rooms
      final chatNotifier = Provider.of<ChatNotifier>(context, listen: false);
      await chatNotifier.initAndListenToChatRooms(_currentUser!.id!);
      debugPrint(
        '[AuthProvider.prefetchUserData] Chat rooms prefetch initiated.',
      );

      // Role-specific data
      if (isDoctor) {
        debugPrint(
          '[AuthProvider.prefetchUserData] Prefetching doctor-specific data...',
        );
        final appointmentProvider = Provider.of<AppointmentProvider>(
          context,
          listen: false,
        );
        final patientProvider = Provider.of<PatientProvider>(
          context,
          listen: false,
        );

        await appointmentProvider.fetchDoctorAppointments(_currentUser!.id!);
        debugPrint(
          '[AuthProvider.prefetchUserData] Doctor appointments prefetch initiated.',
        );
        await patientProvider.fetchPatientsForDoctor(_currentUser!.id!);
        debugPrint(
          '[AuthProvider.prefetchUserData] Doctor\'s patients prefetch initiated.',
        );
      } else if (isPatient) {
        debugPrint(
          '[AuthProvider.prefetchUserData] Prefetching patient-specific data...',
        );
        final appointmentProvider = Provider.of<AppointmentProvider>(
          context,
          listen: false,
        );
        final medicalRecordProvider = Provider.of<MedicalRecordProvider>(
          context,
          listen: false,
        );

        await appointmentProvider.fetchPatientAppointments(_currentUser!.id!);
        debugPrint(
          '[AuthProvider.prefetchUserData] Patient appointments prefetch initiated.',
        );
        await medicalRecordProvider.fetchPatientMedicalRecords(
          _currentUser!.id!,
        );
        debugPrint(
          '[AuthProvider.prefetchUserData] Patient medical records prefetch initiated.',
        );
      } else if (isAdmin) {
        debugPrint(
          '[AuthProvider.prefetchUserData] Prefetching admin-specific data (example)...',
        );
        // Example: Fetch all users list if admin dashboard needs it immediately
        // final userProvider = Provider.of<UserProvider>(context, listen: false);
        // await userProvider.fetchAllUsers(); // Assuming fetchAllUsers exists
        // debugPrint('[AuthProvider.prefetchUserData] All users prefetch initiated for admin.');
        // Add other admin-specific prefetching as needed.
      }

      debugPrint(
        '[AuthProvider.prefetchUserData] Data prefetch sequence completed for user: ${_currentUser!.id}',
      );
    } catch (e) {
      _error = 'Failed during data prefetch: ${e.toString()}';
      debugPrint(
        '[AuthProvider.prefetchUserData] Error during prefetch sequence: $e',
      );
      notifyListeners();
    } finally {
      // If a global prefetch loading state was set, reset it.
      // _isLoading = false;
      // notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
