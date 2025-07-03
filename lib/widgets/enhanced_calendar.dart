import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment_model.dart';
import '../utils/theme.dart';
import '../../utils/admin_theme.dart';

class EnhancedCalendar extends StatefulWidget {
  final List<Appointment> appointments;
  final DateTime selectedDay;
  final DateTime focusedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final CalendarFormat calendarFormat;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final Function(List<Appointment> appointments, DateTime day) getAppointmentsForDay;

  const EnhancedCalendar({
    super.key,
    required this.appointments,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.calendarFormat,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.getAppointmentsForDay,
  });

  @override
  State<EnhancedCalendar> createState() => _EnhancedCalendarState();
}

class _EnhancedCalendarState extends State<EnhancedCalendar> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCalendarHeader(DateTime focusedDay) {
    final headerText = DateFormat.yMMMM('ar').format(focusedDay);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Text(
            headerText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _CalendarFormatButton(
            calendarFormat: widget.calendarFormat,
            onFormatChanged: widget.onFormatChanged,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Appointment> _getAppointmentsForDay(DateTime day) {
    return widget.getAppointmentsForDay(widget.appointments, day);
  }

  // Get color based on appointment statuses for the day
  Color _getDayColor(DateTime day) {
    final appointments = _getAppointmentsForDay(day);
    if (appointments.isEmpty) {
      return Colors.transparent;
    }

    // Check if any appointment is scheduled
    bool hasScheduled = appointments.any((appointment) => appointment.status == 'scheduled');
    bool hasCompleted = appointments.any((appointment) => appointment.status == 'completed');
    bool hasCancelled = appointments.any((appointment) => appointment.status == 'cancelled');

    if (hasScheduled) {
      return Colors.blue.withOpacity(0.7);
    } else if (hasCompleted) {
      return Colors.green.withOpacity(0.7);
    } else if (hasCancelled) {
      return Colors.red.withOpacity(0.7);
    }
    
    return Colors.grey.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildCalendarHeader(widget.focusedDay),
      Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: widget.focusedDay,
            calendarFormat: widget.calendarFormat,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
            onDaySelected: widget.onDaySelected,
            onFormatChanged: widget.onFormatChanged,
            onPageChanged: widget.onPageChanged,
            eventLoader: _getAppointmentsForDay,
            startingDayOfWeek: StartingDayOfWeek.saturday, // Week starts with Saturday in Arabic calendar
            daysOfWeekHeight: 40,
            rowHeight: 60,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                
                return Positioned(
                  bottom: 1,
                  right: 1,
                  child: _buildEventsMarker(date, events),
                );
              },
              // Custom day cell builder
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, false);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, true, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, false, true);
              },
              // We'll handle the case when today is selected in the other builders
            ),
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              markersAnchor: 0.7,
              markersAutoAligned: true,
              // We'll handle decoration in custom builders
              todayDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
            headerVisible: false, // We use custom header
          ),
        ),
      ),
      _buildCalendarLegend(),
    ]);
  }

  Widget _buildEventsMarker(DateTime date, List<dynamic> events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        color: _getDayColor(date),
      ),
      width: 20,
      height: 20,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    // Check if there are appointments for this day
    final hasEvents = _getAppointmentsForDay(day).isNotEmpty;
    
    // Background color based on selection/today status
    Color backgroundColor = Colors.transparent;
    if (isSelected) {
      backgroundColor = AppTheme.primaryColor.withOpacity(0.15);
    } else if (isToday) {
      backgroundColor = AppTheme.accentColor.withOpacity(0.15);
    }
    
    // Border color based on selection/today status
    Color borderColor = Colors.transparent;
    if (isSelected) {
      borderColor = AppTheme.primaryColor;
    } else if (isToday) {
      borderColor = AppTheme.accentColor;
    }
    
    // Text color based on selection/today/events status
    Color textColor = Theme.of(context).textTheme.bodyMedium!.color!;
    if (hasEvents) {
      textColor = AppTheme.primaryColor;
    }
    if (isSelected) {
      textColor = AppTheme.primaryColor;
    } else if (isToday) {
      textColor = AppTheme.accentColor;
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      margin: const EdgeInsets.all(4),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: hasEvents || isSelected || isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(AdminTheme.pendingColor, 'مواعيد قيد الإنتظار '),
          _buildLegendItem(Colors.green, 'مواعيد مكتملة'),
          _buildLegendItem(Colors.red, 'مواعيد ملغية'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _CalendarFormatButton extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final Function(CalendarFormat) onFormatChanged;

  const _CalendarFormatButton({
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        // Toggle between month, 2 weeks, and week
        final formats = [CalendarFormat.month, CalendarFormat.twoWeeks, CalendarFormat.week];
        final currentIndex = formats.indexOf(calendarFormat);
        final nextIndex = (currentIndex + 1) % formats.length;
        onFormatChanged(formats[nextIndex]);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getFormatButtonText(),
              style: TextStyle(color: AppTheme.primaryColor)),
          const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  String _getFormatButtonText() {
    switch (calendarFormat) {
      case CalendarFormat.month:
        return 'شهر';
      case CalendarFormat.twoWeeks:
        return 'أسبوعين';
      case CalendarFormat.week:
        return '\u0623\u0633\u0628\u0648\u0639';
      // No default needed as all cases are covered
    }
  }
}
