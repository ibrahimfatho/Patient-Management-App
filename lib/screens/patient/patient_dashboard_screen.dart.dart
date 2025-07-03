/*import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_record_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/patient_theme.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/patient_appointment_card.dart';
import '../auth/login_screen.dart';
import 'patient_appointment_details_screen.dart';
import 'patient_medical_record_details_screen.dart';
import 'patient_notifications_screen.dart';
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
        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
        final patient = await patientProvider.getPatientByPhone(user.username);
        
        if (patient != null) {
          debugPrint('Patient found: ${patient.name} with ID: ${patient.id}');
          
          // Load appointments and medical records for this patient
          final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
          final medicalRecordProvider = Provider.of<MedicalRecordProvider>(context, listen: false);
          
          await appointmentProvider.fetchPatientAppointments(patient.id!);
          debugPrint('Appointments loaded: ${appointmentProvider.appointments.length}');
          
          await medicalRecordProvider.fetchPatientMedicalRecords(patient.id!);
          debugPrint('Medical records loaded: ${medicalRecordProvider.medicalRecords.length}');
        } else {
          debugPrint('No patient found for username: ${user.username}');
        }
      } else {
        debugPrint('No user is currently logged in');
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: PatientTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _getSelectedScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'المواعيد',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.medical_services_outlined),
                activeIcon: Icon(Icons.medical_services),
                label: 'السجل الطبي',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'الإشعارات',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            selectedItemColor: PatientTheme.primaryColor,
            unselectedItemColor: PatientTheme.textSecondaryColor,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
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
        return 'المواعيد الخاصة';
      case 2:
        return 'السجل الطبي';
      case 3:
        return 'الإشعارات';
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
        return const PatientNotificationsScreen();
      default:
        return _buildHomeScreen();
    }
  }

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
            Icon(
              icon,
              color: color,
              size: 28,
            ),
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

    final patientProvider = Provider.of<PatientProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final medicalRecordProvider = Provider.of<MedicalRecordProvider>(context);
    
    if (patientProvider.isLoading || appointmentProvider.isLoading || medicalRecordProvider.isLoading) {
      return const LoadingIndicator();
    }

    if (patientProvider.error != null) {
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
              onPressed: _loadPatientData,
              style: PatientTheme.primaryButtonStyle,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final patient = patientProvider.patients.first;
    final upcomingAppointments = appointmentProvider.appointments
        .where((a) => a.status == 'scheduled')
        .toList();
    
    debugPrint('Total appointments: ${appointmentProvider.appointments.length}');
    debugPrint('Upcoming appointments: ${upcomingAppointments.length}');
    
    // Sort by date (newest first for medical records)
    final records = medicalRecordProvider.medicalRecords;
    records.sort((a, b) => b.date.compareTo(a.date));
    // Get recent records for display on home screen
    final recentRecords = records.length > 2 ? records.sublist(0, 2) : records;

    return Stack(
      children: [
        // Gradient background header
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1976D2),
                const Color(0xFF1976D2).withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient info card
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.password,
                        color: PatientTheme.primaryColor,
                      ),
                      tooltip: 'تغيير كلمة المرور',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PatientChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Info container
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
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          
          // Upcoming Appointments
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المواعيد القادمة',
                  style: PatientTheme.sectionTitleStyle,
                ),
                if (upcomingAppointments.length > 2)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Switch to appointments tab
                      });
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('عرض الكل'),
                    style: TextButton.styleFrom(foregroundColor: PatientTheme.primaryColor),
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
                itemCount: upcomingAppointments.length > 2
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
                          builder: (_) => PatientAppointmentDetailsScreen(
                            appointment: appointment,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          
          if (upcomingAppointments.length > 2) ...[  
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1; // Switch to appointments tab
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('عرض الكل'),
              ),
            ),
          ],

          // Recent Medical Records
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                    style: TextButton.styleFrom(foregroundColor: PatientTheme.primaryColor),
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
                        backgroundColor: PatientTheme.accentColor,
                        child: Icon(
                          Icons.medical_services,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatientMedicalRecordDetailsScreen(
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
          
          // Bottom padding
          const SizedBox(height: 24),
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
                final patientProvider = Provider.of<PatientProvider>(context, listen: false);
                if (patientProvider.patients.isNotEmpty) {
                  appointmentProvider.fetchPatientAppointments(patientProvider.patients.first.id!);
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

    // Group appointments by status
    final pendingAppointments = appointments.where((a) => a.status == 'scheduled').toList();
    final completedAppointments = appointments.where((a) => a.status == 'completed').toList();
    final cancelledAppointments = appointments.where((a) => a.status == 'cancelled').toList();
    
    debugPrint('Appointments breakdown:');
    debugPrint('- Scheduled: ${pendingAppointments.length}');
    debugPrint('- Completed: ${completedAppointments.length}');
    debugPrint('- Cancelled: ${cancelledAppointments.length}');

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendingAppointments.isNotEmpty) ...[
              Text(
                'المواعيد القادمة',
                style: PatientTheme.sectionTitleStyle,
              ),
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatientAppointmentDetailsScreen(
                            appointment: appointment,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            
            if (completedAppointments.isNotEmpty) ...[
              Text(
                'المواعيد المكتملة',
                style: PatientTheme.sectionTitleStyle,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedAppointments.length,
                itemBuilder: (ctx, index) {
                  final appointment = completedAppointments[index];
                  return PatientAppointmentCard(
                    appointment: appointment,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatientAppointmentDetailsScreen(
                            appointment: appointment,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            
            if (cancelledAppointments.isNotEmpty) ...[
              Text(
                'المواعيد الملغاة',
                style: PatientTheme.sectionTitleStyle,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cancelledAppointments.length,
                itemBuilder: (ctx, index) {
                  final appointment = cancelledAppointments[index];
                  return PatientAppointmentCard(
                    appointment: appointment,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatientAppointmentDetailsScreen(
                            appointment: appointment,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
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
                final patientProvider = Provider.of<PatientProvider>(context, listen: false);
                if (patientProvider.patients.isNotEmpty) {
                  medicalRecordProvider.fetchPatientMedicalRecords(patientProvider.patients.first.id!);
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

    // Sort by date (newest first)
    records.sort((a, b) => b.date.compareTo(a.date));

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('التاريخ: ${record.date}'),
                    ],
                  ),
                  if (record.prescription?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.medication, size: 16, color: Colors.grey),
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PatientMedicalRecordDetailsScreen(
                      medicalRecord: record,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}*/
