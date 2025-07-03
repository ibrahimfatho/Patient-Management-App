import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/admin_theme.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/enhanced_calendar.dart';
import '../../widgets/enhanced_list_view.dart';
import '../../widgets/loading_indicator.dart';
import 'add_appointment_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AppointmentProvider>(
        context,
        listen: false,
      ).fetchAllAppointments();
    });
  }

  List<Appointment> _getAppointmentsForDay(
    List<Appointment> appointments,
    DateTime day,
  ) {
    final formattedDay = DateFormat('yyyy-MM-dd').format(day);
    return appointments
        .where((appointment) => appointment.date == formattedDay)
        .toList();
  }

  void _showDeleteConfirmation(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text(
              'هل أنت متأكد من حذف موعد المريض ${appointment.patientName}؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Provider.of<AppointmentProvider>(
                    context,
                    listen: false,
                  ).deleteAppointment(appointment.id!).then((success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حذف الموعد بنجاح'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('فشل في حذف الموعد'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  });
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildNestedScrollView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddAppointmentScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNestedScrollView() {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, _) {
        final appointments = _getAppointmentsForDay(
          appointmentProvider.appointments,
          _selectedDay,
        );

        // Create appointment list items
        final appointmentItems =
            appointments.map((appointment) {
              // Create status chip for the appointment
              final statusChip = StatusChip(
                label: _getStatusText(appointment.status),
                color: _getStatusColor(appointment.status),
                icon: _getStatusIcon(appointment.status),
              );

              // Create detail items
              final details = [
                DetailItem(icon: Icons.access_time, text: appointment.time),
                statusChip,
              ];

              // Expanded content for notes if available
              Widget? expandedContent;
              if (appointment.notes != null && appointment.notes!.isNotEmpty) {
                expandedContent = Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'ملاحظات: ${appointment.notes}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }

              return EnhancedListItem(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: _getStatusColor(
                    appointment.status,
                  ).withOpacity(0.1),
                  child: Icon(
                    _getStatusIcon(appointment.status),
                    color: _getStatusColor(appointment.status),
                  ),
                ),
                title: Text(
                  appointment.patientName ?? 'غير معروف',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  'الطبيب: ${appointment.doctorName ?? "غير معروف"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                details: details,
                expandedContent: expandedContent,
                isExpanded: false,
                onToggleExpand:
                    expandedContent != null
                        ? () {
                          // This would require state management if we want to toggle expansion
                          // For simplicity, we'll leave it as a placeholder and implement fully later
                        }
                        : null,
                trailing: PopupMenuButton(
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('تعديل'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => AddAppointmentScreen(
                                  appointment: appointment,
                                  readOnly: false, // Edit mode
                                ),
                          ),
                        );
                        break;
                      case 'delete':
                        _showDeleteConfirmation(context, appointment);
                        break;
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => AddAppointmentScreen(
                            appointment: appointment,
                            readOnly:
                                true, // Always show in read-only mode when clicked
                          ),
                    ),
                  );
                },
              );
            }).toList();

        // Create empty state widget
        final emptyStateWidget = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, color: Colors.grey, size: 60),
              const SizedBox(height: 16),
              Text(
                'لا توجد مواعيد في هذا اليوم',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(background: _buildCalendar()),
                title:
                    innerBoxIsScrolled
                        ? Text(
                          DateFormat.yMMMd('ar').format(_selectedDay),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                          ),
                        )
                        : null,
              ),
            ];
          },
          body:
              appointmentProvider.isLoading
                  ? const Center(child: LoadingIndicator())
                  : appointmentProvider.error != null
                  ? Center(
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
                        ElevatedButton(
                          onPressed:
                              () => appointmentProvider.fetchAllAppointments(),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                  : appointmentItems.isEmpty
                  ? emptyStateWidget
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: appointmentItems.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: appointmentItems[index],
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    return Consumer<AppointmentProvider>(
      builder: (ctx, appointmentProvider, child) {
        final appointments = appointmentProvider.appointments;

        return EnhancedCalendar(
          appointments: appointments,
          selectedDay: _selectedDay,
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          getAppointmentsForDay: _getAppointmentsForDay,
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return AdminTheme.pendingColor;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.event;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.event_note;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'قيد الإنتظار';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }
}
