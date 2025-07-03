import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Utility class to ensure Firebase access is maintained during long sessions
class FirebaseAccessUtil {
  /// Ensures Firebase token is valid before performing Firebase operations
  /// 
  /// This method should be called before any Firebase operation that might
  /// fail due to token expiration during long sessions.
  /// 
  /// Returns true if token is valid and operation can proceed
  static Future<bool> ensureValidAccess(BuildContext context) async {
    try {
      // Get the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if user is logged in
      if (!authProvider.isLoggedIn) {
        print('[FirebaseAccessUtil] User not logged in');
        return false;
      }
      
      // Ensure token is valid
      final isValid = await authProvider.ensureValidToken();
      if (!isValid) {
        print('[FirebaseAccessUtil] Token refresh failed');
        
        // Show a snackbar to inform the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('جلسة المستخدم منتهية. يرجى إعادة تسجيل الدخول.'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Logout user if token refresh failed
        await authProvider.logout();
        
        // Navigate to login screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      }
      
      return true;
    } catch (e) {
      print('[FirebaseAccessUtil] Error ensuring valid access: $e');
      return false;
    }
  }
}
