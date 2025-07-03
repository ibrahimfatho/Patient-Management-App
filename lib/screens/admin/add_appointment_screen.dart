import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../../models/user_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Appointment? appointment;
  final String? patientId;
  final bool readOnly; // Add readOnly parameter

  const AddAppointmentScreen({
    Key? key,
    this.appointment,
    this.patientId,
    this.readOnly = false, // Default to false (edit mode)
  }) : super(key: key);

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedDoctorId;
  String _status = 'scheduled';

  final List<String> _statusOptions = ['scheduled', 'completed', 'cancelled'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize patient and user providers
    Future.microtask(() {
      Provider.of<PatientProvider>(context, listen: false).fetchPatients();
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });

    // If editing an existing appointment
    if (widget.appointment != null) {
      _dateController.text = widget.appointment!.date;
      _timeController.text = widget.appointment!.time;
      _notesController.text = widget.appointment!.notes ?? '';
      _selectedPatientId = widget.appointment!.patientId;
      _selectedDoctorId = widget.appointment!.doctorId;
      _status = widget.appointment!.status;
    } else if (widget.patientId != null) {
      // If creating a new appointment for a specific patient
      _selectedPatientId = widget.patientId;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _patientSearchController.dispose();
    _doctorSearchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? initialDate;
    try {
      initialDate =
          _dateController.text.isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(_dateController.text)
              : DateTime.now();
    } catch (e) {
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    // Check if a date is selected first
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار التاريخ أولاً'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    TimeOfDay initialTime;
    try {
      final timeStr = _timeController.text;
      final parts = timeStr.split(':');
      initialTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
      final selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        picked.hour,
        picked.minute,
      );

      // We only need to check the time if the date is today.
      // The date picker already prevents past dates.
      if (selectedDateTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن اختيار وقت في الماضي'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate that a patient and doctor are selected
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار المريض'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار الطبيب'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Validate that the selected date and time are not in the past
    try {
      final selectedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
      final timeParts = _timeController.text.split(':');
      final selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );

      final selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      if (selectedDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن حجز موعد في وقت قد مضى.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('صيغة التاريخ أو الوقت غير صالحة.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get providers
    final appointmentProvider = Provider.of<AppointmentProvider>(
      context,
      listen: false,
    );
    final patientProvider = Provider.of<PatientProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Fetch patient name
    String? patientName;
    try {
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == _selectedPatientId,
      );
      patientName = patient.name;
    } catch (e) {
      // Handle error silently or show a message
    }

    // Fetch doctor name
    String? doctorName;
    try {
      final doctor = userProvider.users.firstWhere(
        (u) => u.id == _selectedDoctorId && u.role == 'doctor',
      );
      doctorName = doctor.name;
    } catch (e) {
      // Handle error
    }

    if (patientName == null || doctorName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل في جلب اسم المريض أو الطبيب. الرجاء المحاولة مرة أخرى.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final appointment = Appointment(
      id: widget.appointment?.id,
      patientId: _selectedPatientId!,
      doctorId: _selectedDoctorId!,
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      status: _status,
      notes: _notesController.text.trim(),
      patientName: patientName,
      doctorName: doctorName,
    );

    bool success;
    if (widget.appointment == null) {
      success = await appointmentProvider.addAppointment(appointment);
    } else {
      success = await appointmentProvider.updateAppointment(appointment);
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appointment == null
                ? 'تم إضافة الموعد بنجاح'
                : 'تم تحديث الموعد بنجاح',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appointment == null
                ? 'فشل في إضافة الموعد'
                : 'فشل في تحديث الموعد',
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
          widget.appointment == null
              ? 'إضافة موعد جديد'
              : widget.readOnly
              ? 'تفاصيل الموعد'
              : 'تعديل الموعد',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            widget.readOnly
                ? _buildReadOnlyDetails() // Use a dedicated method for read-only view
                : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPatientDropdown(),
                      _buildDoctorDropdown(),
                      CustomTextField(
                        label: 'التاريخ',
                        hint: 'YYYY-MM-DD',
                        controller: _dateController,
                        readOnly: true, // Always read-only for date picker
                        onTap:
                            widget.readOnly
                                ? null
                                : () => _selectDate(
                                  context,
                                ), // Disable onTap in read-only mode
                        suffixIcon:
                            widget.readOnly
                                ? null
                                : const Icon(
                                  Icons.calendar_today,
                                ), // Hide icon in read-only mode
                        validator:
                            widget.readOnly
                                ? null
                                : (value) {
                                  // No validation in read-only mode
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال تاريخ الموعد';
                                  }
                                  return null;
                                },
                      ),
                      CustomTextField(
                        label: 'الوقت',
                        hint: 'HH:MM',
                        controller: _timeController,
                        readOnly: true, // Always read-only for time picker
                        onTap:
                            widget.readOnly
                                ? null
                                : () => _selectTime(
                                  context,
                                ), // Disable onTap in read-only mode
                        suffixIcon:
                            widget.readOnly
                                ? null
                                : const Icon(
                                  Icons.access_time,
                                ), // Hide icon in read-only mode
                        validator:
                            widget.readOnly
                                ? null
                                : (value) {
                                  // No validation in read-only mode
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال وقت الموعد';
                                  }
                                  return null;
                                },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الحالة',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _status,
                                isExpanded: true,
                                items:
                                    _statusOptions.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(_getStatusText(value)),
                                      );
                                    }).toList(),
                                onChanged:
                                    widget.readOnly
                                        ? null
                                        : (newValue) {
                                          // Disable dropdown in read-only mode
                                          setState(() {
                                            _status = newValue!;
                                          });
                                        },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                      CustomTextField(
                        label: 'ملاحظات',
                        hint: 'أدخل ملاحظات إضافية (اختياري)',
                        controller: _notesController,
                        readOnly:
                            widget.readOnly, // Make read-only in view mode
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      // Only show the save button if not in read-only mode
                      if (!widget.readOnly)
                        CustomButton(
                          text:
                              widget.appointment == null
                                  ? 'إضافة موعد'
                                  : 'تحديث الموعد',
                          onPressed: _saveAppointment,
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

  // Controllers for the search fields
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _doctorSearchController = TextEditingController();
  // State variables to track if dropdowns are open
  bool _isPatientDropdownOpen = false;
  bool _isDoctorDropdownOpen = false;
  // State variables to hold filtered lists
  List<Patient> _filteredPatients = [];
  List<User> _filteredDoctors = [];

  // Filter patients based on search query
  void _filterPatients(List<Patient> allPatients, String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = allPatients;
      } else {
        _filteredPatients =
            allPatients
                .where(
                  (patient) =>
                      patient.name.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (patient.patientNumber != null &&
                          patient.patientNumber!.toLowerCase().contains(
                            query.toLowerCase(),
                          )),
                )
                .toList();
      }
    });
  }

  // Filter doctors based on search query
  void _filterDoctors(List<User> allDoctors, String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = allDoctors;
      } else {
        _filteredDoctors =
            allDoctors
                .where(
                  (doctor) =>
                      doctor.name.toLowerCase().contains(query.toLowerCase()) ||
                      (doctor.email != null &&
                          doctor.email!.toLowerCase().contains(
                            query.toLowerCase(),
                          )),
                )
                .toList();
      }
    });
  }

  Widget _buildPatientDropdown() {
    return Consumer<PatientProvider>(
      builder: (ctx, patientProvider, child) {
        if (patientProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(size: 30),
          );
        }

        final patients = patientProvider.patients;

        // Initialize filtered patients if not already done
        if (_filteredPatients.isEmpty) {
          _filteredPatients = patients;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المريض',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // If in read-only mode, just show the patient name
            if (widget.readOnly && widget.appointment != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Text(
                  widget.appointment!.patientName ?? 'غير معروف',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            // If not in read-only mode, show the searchable dropdown
            else if (widget.patientId ==
                null) // Only show if patientId is not provided
              Column(
                children: [
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _patientSearchController,
                            decoration: InputDecoration(
                              hintText:
                                  _selectedPatientId != null
                                      ? patients
                                          .firstWhere(
                                            (p) => p.id == _selectedPatientId,
                                          )
                                          .name
                                      : 'ابحث عن مريض...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon:
                                  _patientSearchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _patientSearchController.clear();
                                            _filterPatients(patients, '');
                                          });
                                        },
                                      )
                                      : null,
                            ),
                            onChanged: (value) {
                              _filterPatients(patients, value);
                              setState(() {
                                _isPatientDropdownOpen = true;
                              });
                            },
                            onTap: () {
                              setState(() {
                                _isPatientDropdownOpen = true;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isPatientDropdownOpen
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPatientDropdownOpen = !_isPatientDropdownOpen;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Dropdown list
                  if (_isPatientDropdownOpen)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth:
                            MediaQuery.of(context).size.width -
                            32, // Adjust for padding
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(top: 4),
                      child:
                          _filteredPatients.isEmpty
                              ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('لا توجد نتائج'),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredPatients.length,
                                itemBuilder: (context, index) {
                                  final patient = _filteredPatients[index];
                                  return ListTile(
                                    title: Text(patient.name),
                                    subtitle:
                                        patient.patientNumber != null
                                            ? Text(
                                              'رقم المريض: ${patient.patientNumber}',
                                            )
                                            : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedPatientId = patient.id;
                                        _patientSearchController.text =
                                            ''; // Clear search field
                                        _isPatientDropdownOpen =
                                            false; // Close dropdown
                                      });
                                    },
                                    selected: _selectedPatientId == patient.id,
                                    selectedTileColor: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                  );
                                },
                              ),
                    ),
                ],
              )
            // If patientId is provided, show the selected patient name
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Text(
                  patients.firstWhere((p) => p.id == widget.patientId).name,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildDoctorDropdown() {
    return Consumer<UserProvider>(
      builder: (ctx, userProvider, child) {
        if (userProvider.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LoadingIndicator(size: 30),
          );
        }

        final doctors =
            userProvider.users.where((user) => user.role == 'doctor').toList();

        // Initialize filtered doctors if not already done
        if (_filteredDoctors.isEmpty) {
          _filteredDoctors = doctors;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الطبيب',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // If in read-only mode, just show the doctor name
            if (widget.readOnly && widget.appointment != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Text(
                  widget.appointment!.doctorName ?? 'غير معروف',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            // If not in read-only mode, show the searchable dropdown
            else
              Column(
                children: [
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _doctorSearchController,
                            decoration: InputDecoration(
                              hintText:
                                  _selectedDoctorId != null
                                      ? doctors
                                          .firstWhere(
                                            (d) => d.id == _selectedDoctorId,
                                          )
                                          .name
                                      : 'ابحث عن طبيب...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon:
                                  _doctorSearchController.text.isNotEmpty
                                      ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _doctorSearchController.clear();
                                            _filterDoctors(doctors, '');
                                          });
                                        },
                                      )
                                      : null,
                            ),
                            onChanged: (value) {
                              _filterDoctors(doctors, value);
                              setState(() {
                                _isDoctorDropdownOpen = true;
                              });
                            },
                            onTap: () {
                              setState(() {
                                _isDoctorDropdownOpen = true;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isDoctorDropdownOpen
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isDoctorDropdownOpen = !_isDoctorDropdownOpen;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Dropdown list
                  if (_isDoctorDropdownOpen)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                        maxWidth:
                            MediaQuery.of(context).size.width -
                            32, // Adjust for padding
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(top: 4),
                      child:
                          _filteredDoctors.isEmpty
                              ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('لا توجد نتائج'),
                              )
                              : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredDoctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = _filteredDoctors[index];
                                  return ListTile(
                                    title: Text(doctor.name),
                                    subtitle:
                                        doctor.email != null
                                            ? Text(doctor.email!)
                                            : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedDoctorId = doctor.id;
                                        _doctorSearchController.text =
                                            ''; // Clear search field
                                        _isDoctorDropdownOpen =
                                            false; // Close dropdown
                                      });
                                    },
                                    selected: _selectedDoctorId == doctor.id,
                                    selectedTileColor: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                  );
                                },
                              ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
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

  // Build a more visually appealing read-only view for appointment details
  Widget _buildReadOnlyDetails() {
    if (widget.appointment == null) {
      return const Center(child: Text('No appointment data available'));
    }

    final appointment = widget.appointment!;

    // Helper function to build detail items
    Widget _buildDetailItem(String label, String value, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Get status color
    Color getStatusColor(String status) {
      switch (status) {
        case 'scheduled':
          return Colors.blue;
        case 'completed':
          return Colors.green;
        case 'cancelled':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appointment header with status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                appointment.status == 'scheduled'
                    ? Icons.event
                    : appointment.status == 'completed'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: getStatusColor(appointment.status),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: getStatusColor(appointment.status),
                      ),
                    ),
                    Text(
                      '${appointment.date} - ${appointment.time}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Patient and doctor information
        _buildDetailItem(
          'المريض',
          appointment.patientName ?? 'غير معروف',
          icon: Icons.person,
        ),
        _buildDetailItem(
          'الطبيب',
          appointment.doctorName ?? 'غير معروف',
          icon: Icons.medical_services,
        ),

        // Date and time
        _buildDetailItem(
          'التاريخ',
          appointment.date,
          icon: Icons.calendar_today,
        ),
        _buildDetailItem('الوقت', appointment.time, icon: Icons.access_time),

        // Notes section if available
        if (appointment.notes != null && appointment.notes!.isNotEmpty)
          _buildDetailItem('ملاحظات', appointment.notes!, icon: Icons.note),

        const SizedBox(height: 16),

        // Edit button at the bottom
        Center(
          child: CustomButton(
            text: 'تعديل الموعد',
            onPressed: () {
              // Navigate to edit mode
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (_) => AddAppointmentScreen(
                        appointment: appointment,
                        readOnly: false,
                      ),
                ),
              );
            },
            width: 200,
            height: 50,
          ),
        ),
      ],
    );
  }
}
