import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/patient/patient_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initSplash();
  }

  Future<void> _initSplash() async {
    // Get the destination page while the splash screen is showing.
    final Widget destination = await _getLandingPage();

    // Ensure the splash screen is visible for a minimum duration.
    // The auth check happens concurrently.
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      FlutterNativeSplash.remove();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  /// Checks authentication status and determines the appropriate landing page.
  Future<Widget> _getLandingPage() async {
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      
      // Await the first authentication state change to ensure Firebase is initialized.
      final user = await FirebaseAuth.instance.authStateChanges().first;

      if (user == null) {
        return const LoginScreen();
      }

      // Re-check if the widget is still in the tree before proceeding.
      if (!mounted) return const LoginScreen();

      await authProvider.loadCurrentUser(user.uid);
      final appUser = authProvider.currentUser;

      if (appUser == null) {
        // If user record is not found in the database, direct to login.
        return const LoginScreen();
      }

      // Pre-fetch user-specific data for a smoother transition to the dashboard.
      await authProvider.prefetchUserData(context);
      if (!mounted) return const LoginScreen();

      switch (appUser.role) {
        case 'admin':
          return const AdminDashboardScreen();
        case 'doctor':
          return const DoctorDashboardScreen();
        case 'patient':
          return const PatientDashboardScreen();
        default:
          // Fallback for unknown roles.
          debugPrint('Unknown user role: ${appUser.role}, navigating to login.');
          return const LoginScreen();
      }
    } catch (e) {
      debugPrint('Error during splash screen initialization: $e');
      // In case of any error, navigate to the login screen for safety.
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset('assets/icons/Color light.png', height: 100),
            const SizedBox(height: 24),
            // App name
            Text(
              'نظام إدارة المرضى',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 16),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
          ],
        ),
      ),
    );
  }
}
