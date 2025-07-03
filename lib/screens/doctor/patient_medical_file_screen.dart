import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_record_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import '../admin/add_edit_patient_screen.dart';
import 'add_diagnosis_screen.dart';

class PatientMedicalFileScreen extends StatefulWidget {
  final String patientId;

  const PatientMedicalFileScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<PatientMedicalFileScreen> createState() =>
      _PatientMedicalFileScreenState();
}

class _PatientMedicalFileScreenState extends State<PatientMedicalFileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)..addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });

    Future.microtask(() {
      Provider.of<PatientProvider>(
        context,
        listen: false,
      ).selectPatient(widget.patientId);
      Provider.of<MedicalRecordProvider>(
        context,
        listen: false,
      ).fetchPatientMedicalRecords(widget.patientId);
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
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, child) {
        final patient = patientProvider.selectedPatient;
        return Scaffold(
          appBar: AppBar(
            title: const Text('ملف المريض الطبي'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'معلومات المريض'),
                Tab(text: 'التاريخ المرضي'),
                Tab(text: 'التقرير الطبي'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPatientInfoTab(),
              _buildMedicalHistoryTab(),
              _buildMedicalRecordsTab(),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(patient),
        );
      },
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
              const SizedBox(height: 16),
              _buildSectionHeader(
                context,
                'الأدوية والتاريخ العائلي',
                Icons.family_restroom,
              ),
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
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'معلومات إضافية', Icons.info),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
    final hasContent = content != null && content.isNotEmpty;
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
                  hasContent ? content : 'لا يوجد',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasContent ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(Patient? patient) {
    // Show edit patient button on Medical History tab (index 1)
    if (_currentTabIndex == 1) {
      return Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) {
          if (authProvider.isDoctor) {
            return FloatingActionButton(
              onPressed: () {
                if (patient != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddEditPatientScreen(patient: patient),
                    ),
                  );
                }
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'تعديل التاريخ المرضي',
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    // Show add diagnosis button on Medical Records tab (index 2)
    if (_currentTabIndex == 2) {
      return Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) {
          if (authProvider.isDoctor) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => AddDiagnosisScreen(patientId: widget.patientId),
                  ),
                );
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              tooltip: 'إضافة تشخيص',
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return const SizedBox.shrink();
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicalRecordsTab() {
    return Consumer<MedicalRecordProvider>(
      builder: (ctx, medicalRecordProvider, child) {
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
                  color: AppTheme.errorColor,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ: ${medicalRecordProvider.error}',
                  style: const TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إعادة المحاولة',
                  onPressed: () {
                    medicalRecordProvider.fetchPatientMedicalRecords(
                      widget.patientId,
                    );
                  },
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
                  Icons.medical_services_outlined,
                  color: Colors.grey,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد سجلات طبية',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'إضافة تشخيص جديد',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                AddDiagnosisScreen(patientId: widget.patientId),
                      ),
                    );
                  },
                  icon: Icons.add,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (ctx, index) {
            final record = records[index];
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(DateTime.parse(record.date)),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            'الطبيب: ${record.doctorName ?? "غير معروف"}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          // Add edit button for doctors
                          Consumer<AuthProvider>(
                            builder: (ctx, authProvider, _) {
                              final currentUser = authProvider.currentUser;
                              // Only show edit button if current user is the doctor who created the record
                              if (authProvider.isDoctor &&
                                  currentUser != null &&
                                  currentUser.id == record.doctorId) {
                                return IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  tooltip: 'تعديل',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddDiagnosisScreen(
                                              patientId: widget.patientId,
                                              medicalRecord: record,
                                            ),
                                      ),
                                    );
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(
                    ' التشخيص:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.diagnosis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'الوصفة الطبية:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.prescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'ملاحظات:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
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
