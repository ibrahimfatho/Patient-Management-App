import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_record_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/chat_notifier.dart';
import '../../utils/patient_theme.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/patient_appointment_card.dart';
import '../../widgets/badge_icon.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import 'patient_appointment_details_screen.dart';
import 'package:patient_management/screens/patient/patient_profile_screen.dart';
import 'patient_medical_record_details_screen.dart';

import 'patient_change_password_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        // Load patient data based on phone number (username)
        final patientProvider = Provider.of<PatientProvider>(
          context,
          listen: false,
        );
        final patient = await patientProvider.getPatientByPhone(user.username);

        if (patient != null) {
          debugPrint('Patient found: ${patient.name} with ID: ${patient.id}');

          // Load appointments and medical records for this patient
          final appointmentProvider = Provider.of<AppointmentProvider>(
            context,
            listen: false,
          );
          final medicalRecordProvider = Provider.of<MedicalRecordProvider>(
            context,
            listen: false,
          );

          await appointmentProvider.fetchPatientAppointments(patient.id!);
          debugPrint(
            'Appointments loaded: ${appointmentProvider.appointments.length}',
          );

          await medicalRecordProvider.fetchPatientMedicalRecords(patient.id!);
          debugPrint(
            'Medical records loaded: ${medicalRecordProvider.medicalRecords.length}',
          );
        } else {
          debugPrint('No patient found for username: ${user.username}');
        }
      } else {
        debugPrint('No user is currently logged in');
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      // Optionally, show a snackbar or update UI to reflect error
    } finally {
      if (mounted) {
        // Added mounted check for robustness
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد تسجيل الخروج', textAlign: TextAlign.center),
          content: const Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج؟',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // First navigate to login screen to prevent data loading errors
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));

      // Then logout after navigation has started
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      // This will effectively show the LoginScreen if not authenticated.
      // Consider if a post-frame callback for navigation is preferred
      // in some scenarios, but returning the screen directly is common.
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Profile button on the left (which appears on the right in RTL)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PatientProfileScreen(),
                  ),
                );
              },
              tooltip: 'الملف الشخصي',
            ),
            // Spacer to push title to center
            Expanded(
              child: Text(_getScreenTitle(), textAlign: TextAlign.center),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
        backgroundColor: PatientTheme.primaryColor,
        elevation: 0, // Set to 0 for a seamless transition to the gradient
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : Stack(
                // Changed from Column to Stack
                children: [
                  // Gradient background below app bar
                  Container(
                    width: double.infinity,
                    height: 80, // Define the height of the gradient area
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          PatientTheme.primaryColor, // Use theme color
                          PatientTheme.primaryColor.withOpacity(
                            0.0,
                          ), // Fade to transparent
                        ],
                      ),
                    ),
                  ),
                  // Main content - will be layered on top of the gradient
                  _getSelectedScreen(), // Removed the Expanded widget wrapper
                ],
              ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2), // Shadow for the bottom bar
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Consumer<ChatNotifier>(
            builder: (context, chatNotifier, child) {
              final unreadCount = chatNotifier.getTotalUnreadCount();

              return BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'الرئيسية',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today),
                    label: 'المواعيد',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.medical_services_outlined),
                    activeIcon: Icon(Icons.medical_services),
                    label: 'التقرير الطبي',
                  ),
                  BottomNavigationBarItem(
                    icon: BadgeIcon(
                      icon: Icons.chat_outlined,
                      count: unreadCount,
                      showBadge: unreadCount > 0,
                      iconColor:
                          _selectedIndex == 3
                              ? PatientTheme.primaryColor
                              : PatientTheme.textSecondaryColor,
                    ),
                    activeIcon: BadgeIcon(
                      icon: Icons.chat,
                      count: unreadCount,
                      showBadge: unreadCount > 0,
                      iconColor: PatientTheme.primaryColor,
                    ),
                    label: 'المحادثات',
                  ),
                ],
                type: BottomNavigationBarType.fixed,
                selectedItemColor: PatientTheme.primaryColor,
                unselectedItemColor: PatientTheme.textSecondaryColor,
                backgroundColor: Colors.white,
                elevation: 0, // Set to 0 as shadow is handled by the Container
                selectedFontSize: 12,
                unselectedFontSize: 12,
              );
            },
          ),
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'الصفحة الرئيسية';
      case 1:
        return 'المواعيد';
      case 2:
        return 'التقرير الطبي';
      case 3:
        return 'المحادثات';

      default:
        return 'الصفحة الرئيسية';
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildAppointmentsScreen();
      case 2:
        return _buildMedicalRecordsScreen();
      case 3:
        return const ChatListScreen();

      default:
        return _buildHomeScreen();
    }
  }

  // _buildQuickActionCard remains unchanged
  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final patientProvider = Provider.of<PatientProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final medicalRecordProvider = Provider.of<MedicalRecordProvider>(context);

    // This check happens after _isLoading is false.
    // If patient data couldn't be loaded, this will be shown.
    if (patientProvider.patients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: PatientTheme.cancelledColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على بيانات المريض',
              style: TextStyle(color: PatientTheme.cancelledColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatientData, // Retry loading
              style: PatientTheme.primaryButtonStyle,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final patient = patientProvider.patients.first;
    final upcomingAppointments =
        appointmentProvider.appointments
            .where((a) => a.status == 'scheduled')
            .toList();

    debugPrint(
      'Total appointments: ${appointmentProvider.appointments.length}',
    );
    debugPrint('Upcoming appointments: ${upcomingAppointments.length}');

    final records = medicalRecordProvider.medicalRecords;
    records.sort((a, b) => b.date.compareTo(a.date));
    final recentRecords = records.length > 2 ? records.sublist(0, 2) : records;

    // The SingleChildScrollView will allow content to scroll over the gradient if needed.
    // The top margins of the cards will position them correctly over the gradient.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient info card
          // Its top margin (16) will make it appear within the gradient area
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: PatientTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: PatientTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً، ${patient.name}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رقم المريض: ${patient.patientNumber ?? 'غير محدد'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info container
          // Also has a top margin, will be positioned below the patient card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: PatientTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: PatientTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'يمكنك الآن الاطلاع على مواعيدك وسجلاتك الطبية بسهولة',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Upcoming Appointments section (rest of the home screen)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المواعيد القادمة', style: PatientTheme.sectionTitleStyle),
                if (upcomingAppointments.length > 2)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Switch to appointments tab
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('عرض الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: PatientTheme.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          if (upcomingAppointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: PatientTheme.cardDecoration,
                child: const Center(
                  child: Text(
                    'لا توجد مواعيد قادمة',
                    style: TextStyle(color: PatientTheme.textSecondaryColor),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    upcomingAppointments.length > 2
                        ? 2
                        : upcomingAppointments.length,
                itemBuilder: (ctx, index) {
                  final appointment = upcomingAppointments[index];
                  return PatientAppointmentCard(
                    appointment: appointment,
                    isUpcoming: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => PatientAppointmentDetailsScreen(
                                appointment: appointment,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          // This "View All" button logic was slightly different from the one in Row, consolidated here.
          // The original code had this button logic, I am keeping it.

          // Recent Medical Records
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'آخر التقارير الطبية',
                  style: PatientTheme.sectionTitleStyle,
                ),
                if (records.length > 2)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2; // Switch to medical records tab
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('عرض الكل'),
                    style: TextButton.styleFrom(
                      foregroundColor: PatientTheme.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: PatientTheme.cardDecoration,
                child: const Center(
                  child: Text(
                    'لا توجد تقارير طبية',
                    style: TextStyle(color: PatientTheme.textSecondaryColor),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentRecords.length,
                itemBuilder: (ctx, index) {
                  final record = recentRecords[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: PatientTheme.cardDecoration,
                    child: ListTile(
                      title: Text(
                        'تشخيص: ${record.diagnosis}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'د. ${record.doctorName} - ${record.date}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor:
                            PatientTheme
                                .accentColor, // Assuming PatientTheme.accentColor is defined
                        child: Icon(
                          Icons.medical_services,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => PatientMedicalRecordDetailsScreen(
                                  medicalRecord: record,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24), // Bottom padding for scrollable content
        ],
      ),
    );
  }

  Widget _buildAppointmentsScreen() {
    final appointmentProvider = Provider.of<AppointmentProvider>(context);

    if (appointmentProvider.isLoading) {
      return const LoadingIndicator();
    }

    if (appointmentProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: PatientTheme.cancelledColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ: ${appointmentProvider.error}',
              style: const TextStyle(color: PatientTheme.cancelledColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final patientProvider = Provider.of<PatientProvider>(
                  context,
                  listen: false,
                );
                if (patientProvider.patients.isNotEmpty) {
                  appointmentProvider.fetchPatientAppointments(
                    patientProvider.patients.first.id!,
                  );
                } else {
                  _loadPatientData(); // Fallback to full reload if no patient info available
                }
              },
              style: PatientTheme.primaryButtonStyle,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final appointments = appointmentProvider.appointments;
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              color: PatientTheme.textSecondaryColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مواعيد',
              style: TextStyle(
                color: PatientTheme.textSecondaryColor,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatientData,
              style: PatientTheme.primaryButtonStyle,
              child: const Text('تحديث'),
            ),
          ],
        ),
      );
    }

    final pendingAppointments =
        appointments.where((a) => a.status == 'scheduled').toList();
    final completedAppointments =
        appointments.where((a) => a.status == 'completed').toList();
    final cancelledAppointments =
        appointments.where((a) => a.status == 'cancelled').toList();

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(
          16,
        ), // Padding will make content start 16px from top, over gradient
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingAppointments.isNotEmpty) ...[
              Text('المواعيد القادمة', style: PatientTheme.sectionTitleStyle),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingAppointments.length,
                itemBuilder: (ctx, index) {
                  final appointment = pendingAppointments[index];
                  return PatientAppointmentCard(
                    appointment: appointment,
                    isUpcoming: true,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => PatientAppointmentDetailsScreen(
                                  appointment: appointment,
                                ),
                          ),
                        ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            if (completedAppointments.isNotEmpty) ...[
              Text('المواعيد المكتملة', style: PatientTheme.sectionTitleStyle),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedAppointments.length,
                itemBuilder: (ctx, index) {
                  final appointment = completedAppointments[index];
                  return PatientAppointmentCard(
                    appointment: appointment,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => PatientAppointmentDetailsScreen(
                                  appointment: appointment,
                                ),
                          ),
                        ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            if (cancelledAppointments.isNotEmpty) ...[
              Text('المواعيد الملغاة', style: PatientTheme.sectionTitleStyle),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cancelledAppointments.length,
                itemBuilder: (ctx, index) {
                  final appointment = cancelledAppointments[index];
                  return PatientAppointmentCard(
                    appointment: appointment,
                    onTap:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => PatientAppointmentDetailsScreen(
                                  appointment: appointment,
                                ),
                          ),
                        ),
                  );
                },
              ),
            ],
            if (pendingAppointments.isEmpty &&
                completedAppointments.isEmpty &&
                cancelledAppointments.isEmpty &&
                appointments.isNotEmpty)
              Center(
                child: Text(
                  "لا توجد مواعيد تطابق الفئات المحددة.",
                  style: TextStyle(color: PatientTheme.textSecondaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordsScreen() {
    final medicalRecordProvider = Provider.of<MedicalRecordProvider>(context);

    if (medicalRecordProvider.isLoading) {
      return const LoadingIndicator();
    }

    if (medicalRecordProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: PatientTheme.cancelledColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ: ${medicalRecordProvider.error}',
              style: const TextStyle(color: PatientTheme.cancelledColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final patientProvider = Provider.of<PatientProvider>(
                  context,
                  listen: false,
                );
                if (patientProvider.patients.isNotEmpty) {
                  medicalRecordProvider.fetchPatientMedicalRecords(
                    patientProvider.patients.first.id!,
                  );
                } else {
                  _loadPatientData(); // Fallback
                }
              },
              style: PatientTheme.primaryButtonStyle,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final records = medicalRecordProvider.medicalRecords;
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medical_services,
              color: PatientTheme.textSecondaryColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد سجلات طبية',
              style: TextStyle(
                color: PatientTheme.textSecondaryColor,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatientData,
              style: PatientTheme.primaryButtonStyle,
              child: const Text('تحديث'),
            ),
          ],
        ),
      );
    }

    records.sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: ListView.builder(
        padding: const EdgeInsets.all(
          16,
        ), // Padding will make content start 16px from top, over gradient
        itemCount: records.length,
        itemBuilder: (ctx, index) {
          final record = records[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: PatientTheme.cardDecoration,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                'تشخيص: ${record.diagnosis}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('الطبيب: د. ${record.doctorName}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text('التاريخ: ${record.date}'),
                    ],
                  ),
                  if (record.prescription?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.medication,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الوصفة: ${record.prescription}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => PatientMedicalRecordDetailsScreen(
                            medicalRecord: record,
                          ),
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }
}
