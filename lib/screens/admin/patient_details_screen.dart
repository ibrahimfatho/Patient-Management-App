import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/admin_theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/medical_record_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import 'add_edit_patient_screen.dart';
import 'add_appointment_screen.dart';
import '/utils/patient_theme.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      Provider.of<PatientProvider>(
        context,
        listen: false,
      ).selectPatient(widget.patientId);
      Provider.of<MedicalRecordProvider>(
        context,
        listen: false,
      ).fetchPatientMedicalRecords(widget.patientId);
      Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).fetchAllAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month &&
              currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف المريض'),
        actions: [
          Consumer<PatientProvider>(
            builder: (ctx, patientProvider, child) {
              final patient = patientProvider.selectedPatient;
              if (patient == null) {
                return const SizedBox();
              }

              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditPatientScreen(patient: patient),
                    ),
                  );
                },
                tooltip: 'تعديل بيانات المريض',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'معلومات المريض'),
            Tab(text: 'التاريخ المرضي'),
            Tab(text: 'المواعيد'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPatientInfoTab(),
          _buildMedicalHistoryTab(),
          _buildAppointmentsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildMedicalHistoryTab() {
    return Consumer<PatientProvider>(
      builder: (ctx, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const LoadingIndicator();
        }

        if (patientProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${patientProvider.error}',
                  style: const TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إعادة المحاولة',
                  onPressed: () {
                    patientProvider.selectPatient(widget.patientId);
                  },
                ),
              ],
            ),
          );
        }

        final patient = patientProvider.selectedPatient;
        if (patient == null) {
          return const Center(child: Text('لم يتم العثور على بيانات المريض'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                'التاريخ المرضي العام',
                Icons.history,
              ),
              const SizedBox(height: 9),
              _buildMedicalHistoryItem(
                context,
                'الأمراض المزمنة والحادة',
                patient.chronicDiseases,
                Icons.healing,
                Colors.orange.shade50,
                Colors.orange,
              ),
              _buildMedicalHistoryItem(
                context,
                'الحساسية',
                patient.allergies,
                Icons.warning,
                Colors.red.shade50,
                Colors.red,
              ),
              _buildMedicalHistoryItem(
                context,
                'العمليات الجراحية السابقة',
                patient.surgicalHistory,
                Icons.local_hospital,
                Colors.blue.shade50,
                Colors.blue,
              ),

              _buildSectionHeader(
                context,
                'الأدوية والتاريخ العائلي',
                Icons.family_restroom,
              ),
              const SizedBox(height: 9),
              _buildMedicalHistoryItem(
                context,
                'الأدوية الحالية',
                patient.currentMedications,
                Icons.medication,
                Colors.green.shade50,
                Colors.green,
              ),
              _buildMedicalHistoryItem(
                context,
                'التاريخ العائلي للأمراض',
                patient.familyMedicalHistory,
                Icons.people,
                Colors.purple.shade50,
                Colors.purple,
              ),

              _buildSectionHeader(context, 'معلومات إضافية', Icons.info),
              const SizedBox(height: 9),
              _buildMedicalHistoryItem(
                context,
                'التاريخ الاجتماعي',
                patient.socialHistory,
                Icons.group_work,
                Colors.teal.shade50,
                Colors.teal,
              ),
              _buildMedicalHistoryItem(
                context,
                'اللقاحات',
                patient.immunizations,
                Icons.vaccines,
                Colors.cyan.shade50,
                Colors.cyan,
              ),
              if (patient.gender == 'أنثى')
                _buildMedicalHistoryItem(
                  context,
                  'التاريخ النسائي',
                  patient.gynecologicalHistory,
                  Icons.female,
                  Colors.pink.shade50,
                  Colors.pink,
                ),
              _buildMedicalHistoryItem(
                context,
                'ملاحظات إضافية',
                patient.notes,
                Icons.notes,
                Colors.grey.shade200,
                Colors.grey.shade700,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),

      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryItem(
    BuildContext context,
    String title,
    String? content,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (content != null && content.isNotEmpty) ? content : 'لا يوجد',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        (content != null && content.isNotEmpty)
                            ? Colors.black87
                            : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<PatientProvider>(
      builder: (ctx, patientProvider, child) {
        final patient = patientProvider.selectedPatient;
        if (patient == null) {
          return const SizedBox();
        }

        if (_tabController.index == 2) {
          return FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => AddAppointmentScreen(patientId: patient.id ?? ''),
                ),
              );
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildPatientInfoTab() {
    return Consumer<PatientProvider>(
      builder: (ctx, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const LoadingIndicator();
        }

        if (patientProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${patientProvider.error}',
                  style: const TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إعادة المحاولة',
                  onPressed: () {
                    patientProvider.selectPatient(widget.patientId);
                  },
                ),
              ],
            ),
          );
        }

        final patient = patientProvider.selectedPatient;
        if (patient == null) {
          return const Center(child: Text('لم يتم العثور على بيانات المريض'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'العمر: ${_calculateAge(patient.dateOfBirth)} سنة',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'المعلومات الشخصية',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomCard(
                child: Column(
                  children: [
                    // Display patient number at the top with a highlighted style
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.badge,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'رقم المريض:',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            patient.patientNumber ?? 'غير محدد',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    _buildInfoRow(context, 'رقم الهاتف', patient.phone),
                    const Divider(),
                    _buildInfoRow(context, 'العنوان', patient.address),
                    const Divider(),
                    _buildInfoRow(context, 'الجنس', patient.gender),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      'تاريخ الميلاد',
                      patient.dateOfBirth,
                    ),
                    const Divider(),
                    _buildInfoRow(context, 'فصيلة الدم', patient.bloodType),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'المعلومات الطبية',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomCard(
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'التاريخ الطبي',
                      patient.medicalHistory?.isNotEmpty == true
                          ? patient.medicalHistory!
                          : 'لا يوجد',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      'الحساسية',
                      patient.allergies?.isNotEmpty == true
                          ? patient.allergies!
                          : 'لا يوجد',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      'ملاحظات',
                      patient.notes?.isNotEmpty == true
                          ? patient.notes!
                          : 'لا يوجد',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'معلومات إضافية',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CustomCard(
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'تاريخ التسجيل',
                      DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.parse(patient.createdAt)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab() {
    return Consumer2<PatientProvider, AppointmentProvider>(
      builder: (ctx, patientProvider, appointmentProvider, child) {
        final patient = patientProvider.selectedPatient;
        if (patient == null) {
          return const LoadingIndicator();
        }

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
                  color: AppTheme.errorColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${appointmentProvider.error}',
                  style: const TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إعادة المحاولة',
                  onPressed: () {
                    appointmentProvider.fetchAllAppointments();
                  },
                ),
              ],
            ),
          );
        }

        // Filter appointments for this patient
        final patientAppointments =
            appointmentProvider.appointments
                .where(
                  (appointment) => appointment.patientId == (patient.id ?? ''),
                )
                .toList();

        if (patientAppointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد مواعيد لهذا المريض',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إضافة موعد جديد',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => AddAppointmentScreen(
                              patientId: patient.id ?? '',
                            ),
                      ),
                    );
                  },
                  icon: Icons.add,
                ),
              ],
            ),
          );
        }

        // Group appointments by date
        final Map<String, List<Appointment>> appointmentsByDate = {};
        for (final appointment in patientAppointments) {
          if (!appointmentsByDate.containsKey(appointment.date)) {
            appointmentsByDate[appointment.date] = [];
          }
          appointmentsByDate[appointment.date]!.add(appointment);
        }

        // Sort dates in descending order (newest first)
        final sortedDates =
            appointmentsByDate.keys.toList()
              ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (ctx, index) {
            final date = sortedDates[index];
            final dateAppointments = appointmentsByDate[date]!;

            return CustomCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy-MM-dd').format(DateTime.parse(date)),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  ...dateAppointments.map(
                    (appointment) => Column(
                      children: [
                        ListTile(
                          title: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                appointment.time,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          subtitle:
                              appointment.notes != null &&
                                      appointment.notes!.isNotEmpty
                                  ? Text(
                                    'ملاحظات: ${appointment.notes}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  )
                                  : null,
                          trailing: _buildStatusChip(appointment.status),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
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
        color: getStatusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: getStatusColor(status).withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Text(
        getArabicStatus(status),
        style: TextStyle(
          color: getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
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

  String getArabicStatus(String status) {
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
