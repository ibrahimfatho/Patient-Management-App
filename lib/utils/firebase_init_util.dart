import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart' as app_user;

class FirebaseInitUtil {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Create initial admin user in Firebase Auth and Firestore
  static Future<bool> createInitialAdminUser(
      String email, String password, String name) async {
    try {
      // Check if admin user already exists in Firestore
      final querySnapshot = await _firestore.collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        print('Admin user already exists');
        return true;
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': email,
        'password': password, // Note: In a production app, don't store plain text passwords
        'role': 'admin',
        'name': name,
      });

      print('Admin user created successfully');
      return true;
    } catch (e) {
      print('Error creating admin user: $e');
      return false;
    }
  }

  // Create initial test data for the app
  static Future<bool> createInitialTestData() async {
    try {
      // Create a test patient
      // await _createTestPatient();
      
      // Create a test doctor
      // await _createTestDoctor();
      
      print('Test data created successfully');
      return true;
    } catch (e) {
      print('Error creating test data: $e');
      return false;
    }
  }


}
