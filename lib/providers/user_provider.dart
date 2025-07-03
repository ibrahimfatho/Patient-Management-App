import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_user_service.dart';

class UserProvider with ChangeNotifier {
  final FirebaseUserService _userService = FirebaseUserService();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => [..._users];
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _userService.addUser(user);
      if (id != null) {
        await fetchUsers();
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

  // Get user by ID
  Future<User?> getUserById(String id) async {
    try {
      return await _userService.getUserById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  // Get user by patient ID
  Future<User?> getUserByPatientId(String patientId) async {
    try {
      // First fetch all users
      await fetchUsers();
      
      // Find the user with the matching patientId
      for (final user in _users) {
        if (user.patientId == patientId) {
          return user;
        }
      }
      
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }
  
  // Get all users (including patients and doctors)
  Future<List<User>> getAllUsers() async {
    try {
      if (_users.isEmpty) {
        await fetchUsers();
      }
      return _users;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
  
  // Get all doctors
  Future<List<User>> getAllDoctors() async {
    try {
      return await _userService.getAllDoctors();
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<bool> updateUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _userService.updateUser(user);
      if (success) {
        await fetchUsers();
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

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _userService.deleteUser(id);
      if (success) {
        await fetchUsers();
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
