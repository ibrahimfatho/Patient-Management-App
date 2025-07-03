import 'package:flutter/material.dart';
import '../models/medical_record_model.dart';
import '../utils/patient_theme.dart';

class PatientMedicalRecordCard extends StatelessWidget {
  final MedicalRecord medicalRecord;
  final VoidCallback onTap;
  final bool isRecent;

  const PatientMedicalRecordCard({
    Key? key,
    required this.medicalRecord,
    required this.onTap,
    this.isRecent = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: PatientTheme.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Colored accent on the left side
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 6,
                  child: Container(
                    color: PatientTheme.accentColor,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: PatientTheme.accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services,
                          color: PatientTheme.accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تشخيص: ${medicalRecord.diagnosis}',
                              style: PatientTheme.cardTitleStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'د. ${medicalRecord.doctorName} - ${medicalRecord.date}',
                              style: PatientTheme.cardSubtitleStyle,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: PatientTheme.textLightColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                
                if (isRecent)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: PatientTheme.accentColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'جديد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
