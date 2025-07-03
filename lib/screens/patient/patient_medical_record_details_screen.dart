import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medical_record_model.dart';
import '../../providers/patient_provider.dart';
import '../../utils/patient_theme.dart';
import '../../utils/pdf_export_util.dart';

class PatientMedicalRecordDetailsScreen extends StatelessWidget {
  final MedicalRecord medicalRecord;

  const PatientMedicalRecordDetailsScreen({
    Key? key,
    required this.medicalRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التقرير الطبي'),
        backgroundColor: PatientTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient background header
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  PatientTheme.primaryColor,
                  PatientTheme.primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medical Record Header
                Container(
                  decoration: PatientTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: PatientTheme.accentColor
                                  .withOpacity(0.2),
                              child: Icon(
                                Icons.medical_services,
                                color: PatientTheme.accentColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تشخيص: ${medicalRecord.diagnosis}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'تاريخ: ${medicalRecord.date}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Doctor Information
                _buildSectionHeader(context, 'معلومات الطبيب', Icons.person),
                const SizedBox(height: 8),
                Container(
                  decoration: PatientTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildInfoRow(
                      context,
                      'الطبيب المعالج',
                      'د. ${medicalRecord.doctorName ?? "غير معروف"}',
                      Icons.person,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Diagnosis Details
                _buildSectionHeader(
                  context,
                  'التقرير الطبي',
                  Icons.medical_information,
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: PatientTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildInfoRow(
                      context,
                      'التقرير الطبي',
                      medicalRecord.diagnosis,
                      Icons.medical_information,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Prescription Details
                _buildSectionHeader(context, 'الوصفة الطبية', Icons.medication),
                const SizedBox(height: 8),
                Container(
                  decoration: PatientTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildInfoRow(
                      context,
                      'الوصفة الطبية',
                      medicalRecord.prescription,
                      Icons.medication,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Notes (if available)
                if (medicalRecord.notes != null &&
                    medicalRecord.notes!.isNotEmpty) ...[
                  _buildSectionHeader(context, 'ملاحظات إضافية', Icons.note),
                  const SizedBox(height: 8),
                  Container(
                    decoration: PatientTheme.cardDecoration,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildInfoRow(
                        context,
                        'ملاحظات',
                        medicalRecord.notes!,
                        Icons.note,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _printMedicalRecord(context),
                      icon: const Icon(Icons.print),
                      label: const Text('طباعة التقرير'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PatientTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => _shareMedicalRecord(context),
                      icon: const Icon(Icons.share),
                      label: const Text('تصدير ومشاركة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PatientTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: PatientTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _printMedicalRecord(BuildContext context) async {
    try {
      // Get patient information
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      final patients = patientProvider.patients;

      // Check if patients list is empty
      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على بيانات المريض')),
        );
        return;
      }

      // Find the patient by ID or use the first patient
      final patient = patients.firstWhere(
        (p) => p.id == medicalRecord.patientId,
        orElse: () => patients.first,
      );

      // Show loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('جاري تحضير التقرير...')));

      // Generate and print/share PDF
      await PdfExportUtil.printMedicalRecord(
        medicalRecord,
        patient.name,
        patient.patientNumber ?? 'غير محدد',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الطباعة: $e')));
    }
  }

  Future<void> _shareMedicalRecord(BuildContext context) async {
    try {
      // Get patient information
      final patientProvider = Provider.of<PatientProvider>(
        context,
        listen: false,
      );
      final patients = patientProvider.patients;

      // Check if patients list is empty
      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على بيانات المريض')),
        );
        return;
      }

      // Find the patient by ID or use the first patient
      final patient = patients.firstWhere(
        (p) => p.id == medicalRecord.patientId,
        orElse: () => patients.first,
      );

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحضير التقرير للمشاركة...')),
      );

      // Generate and share PDF
      await PdfExportUtil.shareMedicalRecord(
        medicalRecord,
        patient.name,
        patient.patientNumber ?? 'غير محدد',
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء المشاركة: $e')));
    }
  }
}
