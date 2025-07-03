import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getters for Firebase instances
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get patientsCollection => _firestore.collection('patients');
  CollectionReference get appointmentsCollection => _firestore.collection('appointments');
  CollectionReference get medicalRecordsCollection => _firestore.collection('medicalRecords');
  CollectionReference get doctorsCollection => _firestore.collection('doctors');

  // Helper methods for Firestore operations
  Future<DocumentReference> addDocument(CollectionReference collection, Map<String, dynamic> data) {
    return collection.add(data);
  }

  Future<void> updateDocument(CollectionReference collection, String documentId, Map<String, dynamic> data) {
    return collection.doc(documentId).update(data);
  }

  Future<void> deleteDocument(CollectionReference collection, String documentId) {
    return collection.doc(documentId).delete();
  }

  Future<DocumentSnapshot> getDocument(CollectionReference collection, String documentId) {
    return collection.doc(documentId).get();
  }

  Future<QuerySnapshot> getDocuments(CollectionReference collection) {
    return collection.get();
  }

  Future<QuerySnapshot> getDocumentsWhere(
    CollectionReference collection,
    String field,
    dynamic value,
  ) {
    return collection.where(field, isEqualTo: value).get();
  }

  // Convert Firestore timestamp to DateTime
  DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  // Convert DateTime to Firestore timestamp
  Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}
