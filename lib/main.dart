import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'utils/firebase_init_util.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/medical_record_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/user_provider.dart';
import 'providers/chat_notifier.dart';
import 'screens/splash_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/start_chat_screen.dart';
import 'utils/theme.dart';

Future<void> _initializeFirebaseData() async {
  try {
    // Create admin user with email and password
    await FirebaseInitUtil.createInitialAdminUser(
      'admin@example.com',  // Default admin email
      'admin123',           // Default admin password
      'مدير النظام'         // Admin name in Arabic
    );
    
    // Create some test data
    await FirebaseInitUtil.createInitialTestData();
  } catch (e) {
    print('Error initializing Firebase data: $e');
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Create initial admin user for testing
  // This is only for development purposes
  // In a production app, you would create users through a proper registration process
  await _initializeFirebaseData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => ChatNotifier()),
      ],
      child: MaterialApp(
        title: 'نظام إدارة المرضى',
        theme: AppTheme.lightTheme(),
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/chat_list': (context) => const ChatListScreen(),
          '/start_chat': (context) => const StartChatScreen(),
        },
      ),
    );
  }
}
