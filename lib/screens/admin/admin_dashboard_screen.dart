import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/admin_theme.dart';

import '../auth/login_screen.dart';
import 'patient_list_screen.dart';
import 'appointment_list_screen.dart';
import 'user_management_screen.dart';
import 'reports_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        // Load data for the admin dashboard
        final patientProvider = Provider.of<PatientProvider>(
          context,
          listen: false,
        );
        final appointmentProvider = Provider.of<AppointmentProvider>(
          context,
          listen: false,
        );

        await patientProvider.fetchPatients();
        await appointmentProvider.fetchAllAppointments();

        debugPrint('Admin ID: ${currentUser.id}');
        debugPrint('Patients loaded: ${patientProvider.patients.length}');
        debugPrint(
          'Appointments loaded: ${appointmentProvider.appointments.length}',
        );
      } else {
        debugPrint('No user is currently logged in');
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
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
    return Scaffold(
      appBar:
          _selectedIndex == 4
              ? null
              : AppBar(
                title: Text(_getScreenTitle()),
                backgroundColor: AdminTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminProfileScreen(),
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
      body:
          _isLoading
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
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: AdminTheme.primaryColor,
          unselectedItemColor: AdminTheme.textSecondaryColor,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
              activeIcon: Icon(Icons.home),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              label: 'المرضى',
              activeIcon: Icon(Icons.people),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'المواعيد',
              activeIcon: Icon(Icons.calendar_today),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_outlined),
              label: 'المستخدمين',
              activeIcon: Icon(Icons.manage_accounts),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              label: 'التقارير',
              activeIcon: Icon(Icons.bar_chart),
            ),
          ],
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
        return 'إدارة المستخدمين';
      case 4:
        return 'التقارير';
      default:
        return ' الصفحة الرئيسية ';
    }
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return const PatientListScreen();
      case 2:
        return const AppointmentListScreen();
      case 3:
        return const UserManagementScreen();
      case 4:
        return const ReportsScreen();
      default:
        return _buildHomeScreen();
    }
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
              color: AdminTheme.cancelledColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'لم يتم العثور على بيانات المسؤول',
              style: TextStyle(color: AdminTheme.cancelledColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAdminData,
              style: AdminTheme.primaryButtonStyle,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    // Get system stats
    // Filter for today's data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final newPatientsToday =
        patientProvider.patients.where((p) {
          try {
            final createdAt = DateTime.parse(p.createdAt);
            return createdAt.isAfter(today);
          } catch (e) {
            return false;
          }
        }).length;

    final todayAppointments =
        appointmentProvider.appointments.where((a) {
          try {
            final appointmentDate = DateTime.parse(a.date);
            return appointmentDate.year == today.year &&
                appointmentDate.month == today.month &&
                appointmentDate.day == today.day;
          } catch (e) {
            return false;
          }
        }).toList();

    final totalAppointments = todayAppointments.length;
    final scheduledAppointments =
        todayAppointments.where((a) => a.status == 'scheduled').length;
    final completedAppointments =
        todayAppointments.where((a) => a.status == 'completed').length;
    final cancelledAppointments =
        todayAppointments.where((a) => a.status == 'cancelled').length;

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
                AdminTheme.primaryColor,
                AdminTheme.primaryColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Dashboard Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: AdminTheme.cardDecoration,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                        color: AdminTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرحباً، ${currentUser.name}',
                            style: Theme.of(context).textTheme.titleLarge!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مسجل',
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: AdminTheme.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // System Statistics
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'إحصائيات اليوم',
                  style: AdminTheme.sectionTitleStyle,
                ),
              ),

              // Main Stats Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AdminTheme.primaryColor,
                      AdminTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AdminTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'إحصائيات عامة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMainStatItem(
                          title: 'المرضى',
                          value: newPatientsToday.toString(),
                          icon: Icons.people,
                        ),
                        _buildMainStatItem(
                          title: 'المواعيد',
                          value: totalAppointments.toString(),
                          icon: Icons.calendar_today,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'المواعيد المجدولة',
                        value: scheduledAppointments.toString(),
                        icon: Icons.schedule,
                        color: AdminTheme.pendingColor,
                        subtitle: 'بانتظار الموعد',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: 'المواعيد المكتملة',
                        value: completedAppointments.toString(),
                        icon: Icons.check_circle,
                        color: AdminTheme.completedColor,
                        subtitle: 'تم الانتهاء',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cancelled Appointments
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatCard(
                  title: 'المواعيد الملغاة',
                  value: cancelledAppointments.toString(),
                  icon: Icons.cancel,
                  color: AdminTheme.cancelledColor,
                  subtitle: 'تم الإلغاء',
                ),
              ),

              const SizedBox(height: 16),

              // System Health Card
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AdminTheme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemHealthItem({
    required String title,
    required String status,
    required IconData icon,
    required bool isActive,
  }) {
    return Row(
      children: [
        Icon(icon, color: isActive ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
