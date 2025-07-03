import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart' as app_user;
import 'firebase_service.dart';
import 'firebase_auth_service.dart';

class FirebaseUserService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Get reference to users collection
  CollectionReference get usersCollection => _firebaseService.usersCollection;

  // Get all users
  Future<List<app_user.User>> getAllUsers() async {
    try {
      final querySnapshot = await usersCollection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return app_user.User.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      final docSnapshot = await usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return app_user.User.fromMap({
          'id': docSnapshot.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
  
  // Get all doctors
  Future<List<app_user.User>> getAllDoctors() async {
    try {
      final querySnapshot = await usersCollection
          .where('role', isEqualTo: 'doctor')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return app_user.User.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting all doctors: $e');
      return [];
    }
  }

  // Get user by username
  Future<app_user.User?> getUserByUsername(String username) async {
    try {
      final querySnapshot = await usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return app_user.User.fromMap({
          'id': doc.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  // Add a new user
  Future<String?> addUser(app_user.User user) async {
    try {
      String? userId;
      UserCredential? authResult;
      final timestamp = DateTime.now().toIso8601String();
      String constructedEmail = ''; // To store the email used for auth
      
      // 1. Create user in Firebase Auth first
      try {
        // Format email based on username and role
        constructedEmail = user.role == 'patient' 
            ? '${user.username}@patient.com'
            : '${user.username}@${user.role}.com';
        
        // Create user in Firebase Auth
        authResult = await _firebaseService.auth.createUserWithEmailAndPassword(
          email: constructedEmail, // Use the constructed email
          password: user.password ?? '123456', // Use provided password or default
        );
        
        // Get the Firebase Auth UID to use as our Firestore document ID
        userId = authResult.user?.uid;
        print('Successfully created auth account for ${user.role}: ${user.name} with ID: $userId');
      } catch (authError) {
        // If the user already exists, don't treat it as an error
        if (authError is FirebaseAuthException && authError.code == 'email-already-in-use') {
          print('Auth account already exists for user: ${user.username}');
          
          // Try to sign in to get the user ID
          try {
            // Re-construct email for sign-in attempt if auth account already exists
            constructedEmail = user.role == 'patient' 
                ? '${user.username}@patient.com'
                : '${user.username}@${user.role}.com';
                
            authResult = await _firebaseService.auth.signInWithEmailAndPassword(
              email: constructedEmail, // Use the constructed email for sign-in
              password: user.password ?? '123456',
            );
            userId = authResult.user?.uid;
          } catch (signInError) {
            print('Could not sign in to get user ID: $signInError');
            // Generate a unique ID if we can't get the auth ID
            userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${user.username.hashCode}';
          }
        } else {
          print('Warning: Error creating auth account: $authError');
          // Generate a unique ID if we can't create auth account
          userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${user.username.hashCode}';
        }
      }
      
      // 2. Create user in Firestore using the auth UID or generated ID
      if (userId != null) {
        // Prepare user data with all the linking fields
        final userData = {
          'username': user.username,
          'email': constructedEmail, // Store the constructed email used for auth
          'role': user.role,
          'name': user.name,
          'password': user.password, // Store password for reference
          'userId': userId, // Store the unique user ID for reference
          'createdAt': timestamp,
        };
        
        // Add role-specific fields
        if (user.role == 'patient' && user.patientId != null) {
          userData['patientId'] = user.patientId;
        } else if (user.role == 'doctor' && user.doctorId != null) {
          userData['doctorId'] = user.doctorId;
        }
        
        // Create the user document with the same ID as the auth account
        await usersCollection.doc(userId).set(userData);
        
        // If this is a patient, update the patient document to include the userId
        if (user.role == 'patient' && user.patientId != null) {
          try {
            await _firebaseService.patientsCollection.doc(user.patientId).update({
              'userId': userId,
            });
            print('Updated patient document ${user.patientId} with userId: $userId');
          } catch (e) {
            print('Warning: Could not update patient document with userId: $e');
          }
        }
        
        return userId;
      } else {
        throw Exception('Failed to get or generate user ID');
      }
    } catch (e) {
      print('Error adding user: $e');
      return null;
    }
  }

  // Update an existing user
  Future<bool> updateUser(app_user.User user) async {
    try {
      await usersCollection.doc(user.id.toString()).update({
        'username': user.username,
        'role': user.role,
        'name': user.name,
        // We're not updating the password here as it should be handled by Firebase Auth
      });
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete a user
  Future<bool> deleteUser(String userId) async {
    try {
      await usersCollection.doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Get users by role
  Future<List<app_user.User>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await usersCollection
          .where('role', isEqualTo: role)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return app_user.User.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      print('Error getting users by role: $e');
      return [];
    }
  }
}
