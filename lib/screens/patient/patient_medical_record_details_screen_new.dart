import 'package:flutter/material.dart';
import '../../models/medical_record_model.dart';
import '../../utils/patient_theme.dart';

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
                  'التشخيص',
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
                      onPressed: () {
                        // TODO: Implement print functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم تنفيذ هذه الميزة قريباً'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('طباعة التقرير'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PatientTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('سيتم تنفيذ هذه الميزة قريباً'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
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
        Icon(icon, color: PatientTheme.accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
