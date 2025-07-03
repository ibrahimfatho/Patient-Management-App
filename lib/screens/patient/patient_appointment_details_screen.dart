import 'package:flutter/material.dart';
import '../../models/appointment_model.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_card.dart';
import '/utils/patient_theme.dart';

class PatientAppointmentDetailsScreen extends StatelessWidget {
  final Appointment appointment;

  const PatientAppointmentDetailsScreen({Key? key, required this.appointment})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الموعد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment Header
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                            Icons.calendar_today,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'موعد مع د. ${appointment.doctorName}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              _buildStatusChip(appointment.status),
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

            // Appointment Details
            Text(
              'تفاصيل الموعد',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'التاريخ',
                      appointment.date,
                      Icons.calendar_today,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'الوقت',
                      appointment.time,
                      Icons.access_time,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      'الحالة',
                      _getArabicStatus(appointment.status),
                      Icons.info_outline,
                    ),
                    if (appointment.notes?.isNotEmpty == true) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        'ملاحظات',
                        appointment.notes!,
                        Icons.note,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Doctor Information
            Text(
              'معلومات الطبيب',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'اسم الطبيب',
                      'د. ${appointment.doctorName}',
                      Icons.person,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'معلق':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'مكتمل':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'ملغي':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
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
}
