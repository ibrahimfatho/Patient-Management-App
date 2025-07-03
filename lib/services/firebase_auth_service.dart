import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app_user;
import 'firebase_service.dart';
import 'dart:async';

class FirebaseAuthService {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Token refresh timer
  Timer? _tokenRefreshTimer;
  
  // Constructor to initialize token refresh
  FirebaseAuthService() {
    // Set up auth state listener to manage token refresh
    _firebaseService.auth.authStateChanges().listen((User? user) {
      // Cancel existing timer if any
      _tokenRefreshTimer?.cancel();
      
      if (user != null) {
        // User is signed in, start token refresh mechanism
        _startTokenRefresh();
      }
    });
  }
  
  // Get current user
  User? get currentUser => _firebaseService.auth.currentUser;
  
  // Force token refresh
  Future<void> refreshIdToken() async {
    try {
      final user = _firebaseService.auth.currentUser;
      if (user != null) {
        // Force token refresh
        await user.getIdToken(true);
        print('[AuthService] Token refreshed successfully');
      }
    } catch (e) {
      print('[AuthService] Error refreshing token: $e');
      // Don't rethrow as this is a background operation
    }
  }
  
  // Start token refresh mechanism
  void _startTokenRefresh() {
    // Cancel any existing timer
    _tokenRefreshTimer?.cancel();
    
    // Refresh token immediately
    refreshIdToken();
    
    // Set up periodic refresh (every 50 minutes to be safe, as tokens expire after 60 minutes)
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 50), (_) {
      refreshIdToken();
    });
    
    print('[AuthService] Token refresh mechanism started');
  }
  
  // Check and refresh token if needed
  Future<bool> ensureValidToken() async {
    try {
      final user = _firebaseService.auth.currentUser;
      if (user == null) {
        print('[AuthService] No user logged in');
        return false;
      }
      
      // Force token refresh
      await refreshIdToken();
      return true;
    } catch (e) {
      print('[AuthService] Error ensuring valid token: $e');
      return false;
    }
  }
  
  // Sign in with email/username and password
  Future<UserCredential> signInWithEmailAndPassword(String emailOrUsername, String password) async {
    try {
      // Check if input is an email (contains @) or a username
      print('[AuthService.signIn] Attempting sign-in with: $emailOrUsername');
    if (emailOrUsername.contains('@')) {
        // It's an email, proceed with normal sign in
        return await _firebaseService.auth.signInWithEmailAndPassword(
          email: emailOrUsername,
          password: password,
        );
      } else {
        // It's a username, we need to find the corresponding email
        print('[AuthService.signIn] Input is a username. Querying Firestore for user: $emailOrUsername');
        
        // Query Firestore to find user with this username
        final querySnapshot = await _firebaseService.usersCollection
            .where('username', isEqualTo: emailOrUsername)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isEmpty) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'لم يتم العثور على اسم المستخدم او رفم الهاتف',
          );
        }
        
        // Get user data
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'] as String?;
        print('[AuthService.signIn] Found user doc in Firestore: ${userDoc.id}, Data: $userData');
        
        // Construct email based on username and role
        String emailToUse;
        if (role == 'patient') {
          // For patients, email is phone@patient.com
          emailToUse = userData['email'] as String? ?? '$emailOrUsername@patient.com';
          print('[AuthService.signIn] Using stored email from Firestore for Firebase Auth: $emailToUse');
        } else if (role != null) {      // For staff, email is username@role.com
          emailToUse = userData['email'] as String? ?? '$emailOrUsername@$role.com'; // Fallback to constructing email
          print('[AuthService.signIn] Constructed email for Firebase Auth: $emailToUse');
        } else {
          throw Exception('User role is null');
        }
        
        print('[AuthService.signIn] Attempting Firebase Auth with email: $emailToUse');
        
        // Now sign in with the email
        return await _firebaseService.auth.signInWithEmailAndPassword(
          email: emailToUse,
          password: password,
        );
      }
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }
  
  // Sign in with phone number (for patients)
  Future<app_user.User?> signInWithPhonePassword(String phone, String password) async {
    try {
      // Query Firestore for user with this phone number
      final querySnapshot = await _firebaseService.usersCollection
          .where('username', isEqualTo: phone)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found');
      }
      
      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      
      // Verify password (in a real app, you should use proper password hashing)
      if (userData['password'] != password) {
        throw Exception('Invalid password');
      }
      
      // Make sure all required fields are present
      if (!userData.containsKey('username') || 
          !userData.containsKey('password') || 
          !userData.containsKey('role') || 
          !userData.containsKey('name')) {
        throw Exception('User data is incomplete');
      }
      
      // Return user model with explicit type casting
      return app_user.User(
        id: querySnapshot.docs.first.id,
        username: userData['username'] as String,
        password: userData['password'] as String,
        role: userData['role'] as String,
        name: userData['name'] as String,
      );
    } catch (e) {
      print('Error signing in with phone: $e');
      rethrow;
    }
  }
  
  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      return await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }
  
  // Create patient account with phone number as email and default password
  Future<UserCredential?> createPatientAuthAccount(String phoneNumber, {String defaultPassword = '10'}) async {
    try {
      // Format phone number as email by adding @patient.com
      final email = '$phoneNumber@patient.com';
      
      // Create user in Firebase Auth
      print('[AuthService.createPatientAuthAccount] Attempting Firebase Auth with email: $email');
      final userCredential = await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: defaultPassword,
      );
      
      print('Successfully created patient auth account with phone: $phoneNumber');
      print('[AuthService.createPatientAuthAccount] Firebase Auth successful. UID: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      // If the user already exists, don't treat it as an error
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        print('Patient account already exists for phone: $phoneNumber');
        return null;
      }
      
      print('Error creating patient auth account: $e');
      // Don't rethrow - we don't want to block patient creation if auth fails
      return null;
    }
  }
  
  // Create user in Firestore
  Future<void> createUserInFirestore(app_user.User user) async {
    try {
      await _firebaseService.usersCollection.doc(user.id.toString()).set(user.toMap());
    } catch (e) {
      print('Error creating user in Firestore: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      // Cancel token refresh timer
      _tokenRefreshTimer?.cancel();
      _tokenRefreshTimer = null;
      
      await _firebaseService.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  // Get user by ID (Firestore document ID)
  Future<app_user.User?> getUserById(String uid) async {
    print('[AuthService.getUserById] Fetching user by Firestore document ID: $uid');
    try {
      final docSnapshot = await _firebaseService.usersCollection.doc(uid).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        print('[AuthService.getUserById] User found: ${docSnapshot.id}, Data: $data');
        // Ensure the 'id' field from the document is passed to the model
        return app_user.User.fromMap({'id': docSnapshot.id, ...data});
      }
      print('[AuthService.getUserById] User not found with Firestore document ID: $uid');
      return null;
    } catch (e) {
      print('[AuthService.getUserById] Error fetching user by Firestore document ID $uid: $e');
      rethrow;
    }
  }

  // Get user by patient ID
  Future<app_user.User?> getUserByPatientId(String patientId) async {
    print('[AuthService.getUserByPatientId] Fetching user by patientId: $patientId');
    try {
      final querySnapshot = await _firebaseService.usersCollection
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final data = userDoc.data() as Map<String, dynamic>;
        print('[AuthService.getUserByPatientId] User found for patientId $patientId: ${userDoc.id}, Data: $data');
        // Ensure the 'id' field from the document is passed to the model, and userId is populated
        return app_user.User.fromMap({'id': userDoc.id, ...data});
      }
      print('[AuthService.getUserByPatientId] No user found for patientId: $patientId');
      return null;
    } catch (e) {
      print('[AuthService.getUserByPatientId] Error fetching user by patientId $patientId: $e');
      rethrow;
    }
  }
  
  // Get user by username (phone)
  Future<app_user.User?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await _firebaseService.usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return app_user.User.fromMap({
        'id': querySnapshot.docs.first.id,
        ...querySnapshot.docs.first.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting user by username: $e');
      rethrow;
    }
  }
  
  // Change password
  Future<void> changePassword(String userId, String newPassword) async {
    try {
      await _firebaseService.usersCollection.doc(userId).update({
        'password': newPassword,
      });
      
      // If using Firebase Auth with email/password, you would also update there
      if (currentUser != null) {
        await currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }
}
