import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../utils/patient_theme.dart';

class PatientAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  final bool isUpcoming;

  const PatientAppointmentCard({
    Key? key,
    required this.appointment,
    required this.onTap,
    this.isUpcoming = false,
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            appointment.status,
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(appointment.status),
                          color: _getStatusColor(appointment.status),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'موعد مع د. ${appointment.doctorName}',
                              style: PatientTheme.cardTitleStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment.date} - ${appointment.time}',
                              style: PatientTheme.cardSubtitleStyle,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(appointment.status),
                    ],
                  ),
                ),

                if (isUpcoming)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: PatientTheme.accentColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'قادم',
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

  Widget _buildStatusChip(String status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.access_time;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.calendar_today;
    }
  }
}
