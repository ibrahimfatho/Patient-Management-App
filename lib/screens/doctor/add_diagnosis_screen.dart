import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/medical_record_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_record_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class AddDiagnosisScreen extends StatefulWidget {
  final String patientId;
  final MedicalRecord? medicalRecord;

  const AddDiagnosisScreen({
    Key? key,
    required this.patientId,
    this.medicalRecord,
  }) : super(key: key);

  @override
  State<AddDiagnosisScreen> createState() => _AddDiagnosisScreenState();
}

class _AddDiagnosisScreenState extends State<AddDiagnosisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing an existing medical record
    if (widget.medicalRecord != null) {
      _diagnosisController.text = widget.medicalRecord!.diagnosis;
      _prescriptionController.text = widget.medicalRecord!.prescription;
      _notesController.text = widget.medicalRecord!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveDiagnosis() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final medicalRecordProvider = Provider.of<MedicalRecordProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    ); // Added for patientName
    final currentUser = authProvider.currentUser;

    // Fetch patient name
    String? patientNameValue;
    try {
      // Ensure patientProvider has fetched patients.
      // This relies on PatientProvider.patients being populated, e.g., in initState or by another call.
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == widget.patientId,
      );
      patientNameValue = patient.name;
    } catch (e) {
      print(
        'Error fetching patient name for medical record in AddDiagnosisScreen: Patient ID ${widget.patientId} not found in list. $e',
      );
      // patientNameValue will remain null, which is acceptable for the MedicalRecord model.
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم تسجيل الدخول'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final medicalRecord = MedicalRecord(
      id: widget.medicalRecord?.id,
      patientId: widget.patientId,
      doctorId: currentUser.id!,
      date: widget.medicalRecord?.date ?? formattedDate,
      diagnosis: _diagnosisController.text.trim(),
      prescription: _prescriptionController.text.trim(),
      notes: _notesController.text.trim(),
      doctorName: currentUser.name, // Populate doctor's name
      patientName: patientNameValue, // Populate patient's name from variable
    );

    bool success;
    if (widget.medicalRecord == null) {
      // Add new medical record
      success = await medicalRecordProvider.addMedicalRecord(medicalRecord);
    } else {
      // Update existing medical record
      success = await medicalRecordProvider.updateMedicalRecord(medicalRecord);
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.medicalRecord == null
                ? 'تم إضافة التقرير الطبي بنجاح'
                : 'تم تحديث التقرير الطبي بنجاح',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.medicalRecord == null
                ? 'فشل في إضافة التقرير الطبي'
                : 'فشل في تحديث التقرير الطبي',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicalRecord == null
              ? 'إضافة تقرير طبي جديد'
              : 'تعديل التقرير الطبي',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientInfo(),
              CustomTextField(
                label: ' التشخيص',
                hint: 'أدخل التشخيص',
                controller: _diagnosisController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال التشخيص';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'الوصفة الطبية',
                hint: 'أدخل الوصفة الطبية',
                controller: _prescriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال الوصفة الطبية';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'ملاحظات',
                hint: 'أدخل ملاحظات إضافية (اختياري)',
                controller: _notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text:
                    widget.medicalRecord == null
                        ? 'إضافة التقرير الطبي'
                        : 'تحديث التقرير الطبي',
                onPressed: _saveDiagnosis,
                isLoading: _isLoading,
                width: double.infinity,
                height: 50,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfo() {
    return Consumer<PatientProvider>(
      builder: (ctx, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(size: 30),
          );
        }

        final patient = patientProvider.selectedPatient;
        if (patient == null) {
          // Try to select the patient if not already selected
          Future.microtask(() {
            patientProvider.selectPatient(widget.patientId);
          });

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('جاري تحميل بيانات المريض...')),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'معلومات المريض',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الاسم: ${patient.name}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bloodtype, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'فصيلة الدم: ${patient.bloodType}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.secondaryTextColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'العمر: ${_calculateAge(patient.dateOfBirth)} سنة',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (patient.allergies != null &&
                        patient.allergies!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الحساسية: ${patient.allergies}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ],
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
}
