import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/admin_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import '/utils/patient_theme.dart';
import '../../utils/report_pdf_export_util.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Summary data
  int _totalPatients = 0;
  int _totalAppointments = 0;
  int _scheduledAppointments = 0;
  int _completedAppointments = 0;
  int _cancelledAppointments = 0;

  // Gender distribution
  int _malePatients = 0;
  int _femalePatients = 0;

  // Age groups
  int _childrenPatients = 0; // 0-12
  int _teenPatients = 0; // 13-19
  int _adultPatients = 0; // 20-59
  int _seniorPatients = 0; // 60+

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Initial setState is fine here as it's at the beginning of the method
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load patients and appointments data
      await Provider.of<PatientProvider>(
        context,
        listen: false,
      ).fetchPatients();
      await Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).fetchAllAppointments();

      // Process data for reports
      // _processData() updates local fields, then setState will trigger UI update
      _processData();

      // Schedule state update for after the build frame
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check mounted again inside callback
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check mounted again inside callback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
            // Also ensure loading is set to false in case of error
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
      print(
        'Error loading reports data: $e',
      ); // Keep a console log for the error
    }
    // The finally block is tricky with addPostFrameCallback,
    // so we handle setting _isLoading = false within the try and catch post-frame callbacks.
    // If _isLoading must be set false regardless, ensure it's also within a post-frame callback if an error didn't occur.
    // The current structure handles it in both success and error paths' post-frame callbacks.
  }

  void _processData() {
    final patients =
        Provider.of<PatientProvider>(context, listen: false).patients;
    final appointments =
        Provider.of<AppointmentProvider>(context, listen: false).appointments;

    // Calculate summary data
    _totalPatients = patients.length;
    _totalAppointments = appointments.length;
    _scheduledAppointments =
        appointments.where((a) => a.status == 'scheduled').length;
    _completedAppointments =
        appointments.where((a) => a.status == 'completed').length;
    _cancelledAppointments =
        appointments.where((a) => a.status == 'cancelled').length;

    // Calculate gender distribution
    _malePatients = patients.where((p) => p.gender == 'ذكر').length;
    _femalePatients = patients.where((p) => p.gender == 'أنثى').length;

    // Calculate age groups
    final now = DateTime.now();
    for (final patient in patients) {
      try {
        final birthDate = DateTime.parse(patient.dateOfBirth);
        final age =
            now.year -
            birthDate.year -
            (now.month < birthDate.month ||
                    (now.month == birthDate.month && now.day < birthDate.day)
                ? 1
                : 0);

        if (age < 13) {
          _childrenPatients++;
        } else if (age < 20) {
          _teenPatients++;
        } else if (age < 60) {
          _adultPatients++;
        } else {
          _seniorPatients++;
        }
      } catch (e) {
        // Skip invalid dates
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Print and Share buttons on the left (which appears on the right in RTL)
            IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.white),
              onPressed: _isLoading ? null : _printReport,
              tooltip: 'طباعة التقرير',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              onPressed: _isLoading ? null : _shareReport,
              tooltip: 'مشاركة التقرير',
            ),
            SizedBox(width: 67),
            Expanded(
              child: Text('التقارير', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'تحديث البيانات',
          ),
        ],
        backgroundColor: AdminTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ملخص'),
            Tab(text: 'المرضى'),
            Tab(text: 'المواعيد'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const LoadingIndicator()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildPatientsTab(),
                  _buildAppointmentsTab(),
                ],
              ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص النظام',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'المرضى',
                  _totalPatients.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'المواعيد',
                  _totalAppointments.toString(),
                  Icons.calendar_today,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'حالة المواعيد',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            width: double.infinity,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 300,
                height: 250,
                child: _buildAppointmentStatusChart(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'توزيع المرضى',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // If screen is narrow, stack the charts vertically
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          '',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 40),
                          child: _buildGenderDistributionChart(),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'توزيع الفئات العمرية',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          child: _buildAgeDistributionChart(),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Otherwise, show them side by side
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'توزيع الجنس',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildGenderDistributionChart(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'توزيع الفئات العمرية',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            margin: const EdgeInsets.only(left: 16),
                            child: _buildAgeDistributionChart(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab() {
    final patients = Provider.of<PatientProvider>(context).patients;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات المرضى',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع الجنس',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'ذكور',
                          _malePatients,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'إناث',
                          _femalePatients,
                          Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع الفئات العمرية',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'أطفال (0-12)',
                          _childrenPatients,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'مراهقين (13-19)',
                          _teenPatients,
                          Colors.yellow.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'بالغين (20-59)',
                          _adultPatients,
                          Colors.purple,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'كبار السن (60+)',
                          _seniorPatients,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أحدث المرضى المسجلين',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...patients
                      .take(5)
                      .map(
                        (patient) => Column(
                          children: [
                            ListTile(
                              title: Text(patient.name),
                              subtitle: Text('رقم الهاتف: ${patient.phone}'),
                              trailing: Text(
                                'تاريخ الميلاد: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(patient.dateOfBirth))}',
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    final appointments = Provider.of<AppointmentProvider>(context).appointments;

    // Group appointments by date
    final Map<String, List<Appointment>> appointmentsByDate = {};
    for (final appointment in appointments) {
      if (!appointmentsByDate.containsKey(appointment.date)) {
        appointmentsByDate[appointment.date] = [];
      }
      appointmentsByDate[appointment.date]!.add(appointment);
    }

    // Sort dates
    final sortedDates =
        appointmentsByDate.keys.toList()
          ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات المواعيد',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالة المواعيد',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'قيد الإنتظار',
                          _scheduledAppointments,
                          AdminTheme.pendingColor,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'مكتملة',
                          _completedAppointments,
                          Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'ملغاة',
                          _cancelledAppointments,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المواعيد حسب التاريخ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...sortedDates.take(5).map((date) {
                    final dateAppointments = appointmentsByDate[date]!;
                    return ExpansionTile(
                      title: Text(
                        DateFormat('yyyy-MM-dd').format(DateTime.parse(date)),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'عدد المواعيد: ${dateAppointments.length}',
                      ),
                      children:
                          dateAppointments.map((appointment) {
                            return ListTile(
                              title: Text(
                                appointment.patientName ?? 'غير معروف',
                              ),
                              subtitle: Text('الوقت: ${appointment.time}'),
                              trailing: _getStatusChip(appointment.status),
                            );
                          }).toList(),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAppointmentStatusChart() {
    // Handle case when there are no appointments
    if (_scheduledAppointments == 0 &&
        _completedAppointments == 0 &&
        _cancelledAppointments == 0) {
      return const Center(
        child: Text(
          'لا توجد بيانات متاحة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          if (_scheduledAppointments > 0)
            PieChartSectionData(
              value: _scheduledAppointments.toDouble(),
              title: 'قيد الإنتظار',
              color: AdminTheme.pendingColor,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
          if (_completedAppointments > 0)
            PieChartSectionData(
              value: _completedAppointments.toDouble(),
              title: 'مكتملة',
              color: Colors.green,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
          if (_cancelledAppointments > 0)
            PieChartSectionData(
              value: _cancelledAppointments.toDouble(),
              title: 'ملغاة',
              color: Colors.red,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
        ],
      ),
    );
  }

  Widget _buildGenderDistributionChart() {
    // Handle case when there are no patients
    if (_malePatients == 0 && _femalePatients == 0) {
      return const Center(
        child: Text(
          'لا توجد بيانات متاحة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          if (_malePatients > 0)
            PieChartSectionData(
              value: _malePatients.toDouble(),
              title: 'ذكور',
              color: Colors.blue,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
          if (_femalePatients > 0)
            PieChartSectionData(
              value: _femalePatients.toDouble(),
              title: 'إناث',
              color: Colors.pink,
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            ),
        ],
      ),
    );
  }

  Widget _buildAgeDistributionChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxAgeGroupCount().toDouble(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text = '';
                switch (value.toInt()) {
                  case 0:
                    text = '0-12';
                    break;
                  case 1:
                    text = '13-19';
                    break;
                  case 2:
                    text = '20-59';
                    break;
                  case 3:
                    text = '60+';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: _childrenPatients.toDouble(),
                color: Colors.green,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: _teenPatients.toDouble(),
                color: Colors.yellow.shade800,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: _adultPatients.toDouble(),
                color: Colors.purple,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: _seniorPatients.toDouble(),
                color: Colors.teal,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getMaxAgeGroupCount() {
    return [
      _childrenPatients,
      _teenPatients,
      _adultPatients,
      _seniorPatients,
    ].reduce((a, b) => a > b ? a : b);
  }

  Widget _getStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'scheduled':
        color = AdminTheme.pendingColor;
        text = 'قيد الإنتظار';
        break;
      case 'completed':
        color = Colors.green;
        text = 'مكتمل';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ملغي';
        break;
      default:
        color = Colors.grey;
        text = 'غير معروف';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Text(
        _getArabicStatus(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return PatientTheme.pendingColor;
      case 'completed':
        return PatientTheme.completedColor;
      case 'cancelled':
        return PatientTheme.cancelledColor;
      default:
        return PatientTheme.textLightColor;
    }
  }

  String _getArabicStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'قيد الإنتظار';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status; // Return original status if not found
    }
  }

  Map<String, int> _getReportData() {
    return {
      'totalPatients': _totalPatients,
      'totalAppointments': _totalAppointments,
      'scheduledAppointments': _scheduledAppointments,
      'completedAppointments': _completedAppointments,
      'cancelledAppointments': _cancelledAppointments,
      'malePatients': _malePatients,
      'femalePatients': _femalePatients,
      'childrenPatients': _childrenPatients,
      'teenPatients': _teenPatients,
      'adultPatients': _adultPatients,
      'seniorPatients': _seniorPatients,
    };
  }

  void _printReport() {
    ReportPdfExportUtil.printReport(reportData: _getReportData());
  }

  void _shareReport() {
    ReportPdfExportUtil.shareReport(reportData: _getReportData());
  }
}
