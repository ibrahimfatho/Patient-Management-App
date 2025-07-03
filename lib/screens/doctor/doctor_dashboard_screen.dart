import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/chat_notifier.dart';
import 'patient_medical_file_screen.dart';
import '../../utils/doctor_theme.dart';
import '../auth/login_screen.dart';
import 'doctor_patient_list_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/badge_icon.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // Load appointments for this doctor
        final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
        
        await appointmentProvider.fetchDoctorAppointments(user.id!);
        await patientProvider.fetchPatients();
        
        debugPrint('Doctor ID: ${user.id}');
        debugPrint('Appointments loaded: ${appointmentProvider.appointments.length}');
        debugPrint('Patients loaded: ${patientProvider.patients.length}');
      } else {
        debugPrint('No user is currently logged in');
      }
    } catch (e) {
      debugPrint('Error loading doctor data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      
      // Then logout after navigation has started
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: DoctorTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DoctorProfileScreen(),
              ),
            );
          },
          tooltip: 'الملف الشخصي',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          color: Colors.white,
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
              selectedItemColor: DoctorTheme.primaryColor,
              unselectedItemColor: DoctorTheme.textSecondaryColor,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'الرئيسية',
                  activeIcon: Icon(Icons.home),
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'المرضى',
                  activeIcon: Icon(Icons.people),
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  label: 'المواعيد',
                  activeIcon: Icon(Icons.calendar_today),
                ),
                BottomNavigationBarItem(
                  icon: BadgeIcon(
                    icon: Icons.chat_outlined,
                    count: unreadCount,
                    showBadge: unreadCount > 0,
                    iconColor: _selectedIndex == 3 ? DoctorTheme.primaryColor : DoctorTheme.textSecondaryColor,
                  ),
                  label: 'المحادثات',
                  activeIcon: BadgeIcon(
                    icon: Icons.chat,
                    count: unreadCount,
                    showBadge: unreadCount > 0,
                    iconColor: DoctorTheme.primaryColor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getScreenTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'قائمة المرضى';
      case 2:
        return 'المواعيد';
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
        return const DoctorPatientListScreen();
      case 2:
        return const DoctorAppointmentsScreen();
      case 3:
        return const ChatListScreen();
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

  Widget _buildHomeScreen() {
    final authProvider = Provider.of<AuthProvider>(context);
    final appointmentProvider = Provider.of<AppointmentProvider>(context);
    final patientProvider = Provider.of<PatientProvider>(context);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: DoctorTheme.cancelledColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على بيانات الطبيب',
              style: TextStyle(color: DoctorTheme.cancelledColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDoctorData,
              style: DoctorTheme.primaryButtonStyle,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    // Get today's appointments
    final today = DateTime.now();
    final todayFormatted = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // Filter appointments for today only
    final todayAppointments = appointmentProvider.appointments
        .where((a) => a.status == 'scheduled' && a.date == todayFormatted)
        .toList();
    
    // Get total patients count
    final totalPatients = patientProvider.patients.length;
    
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
                DoctorTheme.primaryColor,
                DoctorTheme.primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Dashboard Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: DoctorTheme.cardDecoration,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: DoctorTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.medical_services,
                        size: 30,
                        color: DoctorTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، ${currentUser.name}',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'طبيب',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: DoctorTheme.textSecondaryColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stats Cards
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'الإحصائيات',
                  style: DoctorTheme.sectionTitleStyle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: DoctorTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: DoctorTheme.primaryColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.people,
                                    color: DoctorTheme.primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المرضى',
                                  style: DoctorTheme.cardTitleStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$totalPatients',
                              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: DoctorTheme.primaryColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: DoctorTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: DoctorTheme.accentColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.calendar_today,
                                    color: DoctorTheme.accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'المواعيد اليوم',
                                  style: DoctorTheme.cardTitleStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${todayAppointments.length}',
                              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: DoctorTheme.accentColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Today's Appointments
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مواعيد اليوم',
                      style: DoctorTheme.sectionTitleStyle,
                    ),
                    if (todayAppointments.length > 3)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 2; // Switch to appointments tab
                          });
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('عرض الكل'),
                        style: TextButton.styleFrom(foregroundColor: DoctorTheme.primaryColor),
                      ),
                  ],
                ),
              ),
              if (todayAppointments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: DoctorTheme.cardDecoration,
                    child: const Center(
                      child: Text(
                        'لا توجد مواعيد اليوم',
                        style: TextStyle(color: DoctorTheme.textSecondaryColor),
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
                    itemCount: todayAppointments.length > 3 ? 3 : todayAppointments.length,
                    itemBuilder: (ctx, index) {
                      final appointment = todayAppointments[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: DoctorTheme.cardDecoration,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: DoctorTheme.primaryColor.withOpacity(0.1),
                            child: Text(
                              (appointment.patientName != null && appointment.patientName!.isNotEmpty)
                              ? appointment.patientName!.substring(0, 1)
                              : 'P',
                              style: TextStyle(color: DoctorTheme.primaryColor),
                            ),
                          ),
                          title: Text(appointment.patientName ?? 'مريض'),
                          subtitle: Text('${appointment.date} - ${appointment.time}'),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: DoctorTheme.textSecondaryColor,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PatientMedicalFileScreen(
                                  patientId: appointment.patientId,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
