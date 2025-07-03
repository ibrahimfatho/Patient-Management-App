import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../models/patient_model.dart';
import '../../models/user_model.dart' as app_user;
import '../../providers/patient_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient;

  const AddEditPatientScreen({Key? key, this.patient}) : super(key: key);

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _notesController = TextEditingController();
  String? _patientNumber;
  
  // Controllers for detailed medical history
  final _chronicDiseasesController = TextEditingController();
  final _surgicalHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _familyMedicalHistoryController = TextEditingController();
  final _socialHistoryController = TextEditingController();
  final _immunizationsController = TextEditingController();
  final _gynecologicalHistoryController = TextEditingController();

  String _gender = 'ذكر';
  String _bloodType = 'A+';

  final List<String> _genderOptions = ['ذكر', 'أنثى'];
  final List<String> _bloodTypeOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController.text = widget.patient!.name;
      _phoneController.text = widget.patient!.phone;
      _addressController.text = widget.patient!.address;
      _gender = widget.patient!.gender;
      _dateOfBirthController.text = widget.patient!.dateOfBirth;
      _bloodType = widget.patient!.bloodType;
      _medicalHistoryController.text = widget.patient!.medicalHistory ?? '';
      _allergiesController.text = widget.patient!.allergies ?? '';
      _notesController.text = widget.patient!.notes ?? '';
      _patientNumber = widget.patient!.patientNumber;
      // Note: We don't need to load the image file here as we'll display it from URL
      
      // Initialize detailed medical history fields
      _chronicDiseasesController.text = widget.patient!.chronicDiseases ?? '';
      _surgicalHistoryController.text = widget.patient!.surgicalHistory ?? '';
      _currentMedicationsController.text = widget.patient!.currentMedications ?? '';
      _familyMedicalHistoryController.text = widget.patient!.familyMedicalHistory ?? '';
      _socialHistoryController.text = widget.patient!.socialHistory ?? '';
      _immunizationsController.text = widget.patient!.immunizations ?? '';
      _gynecologicalHistoryController.text = widget.patient!.gynecologicalHistory ?? '';
    } else {
      // Generate a new patient number for new patients
      // Use _isLoading directly to avoid setState during build
      _isLoading = true;
      
      // Use Future.microtask to avoid setState during build
      Future.microtask(() async {
        await _generatePatientNumber();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }
  
  // Generate a unique sequential patient number
  Future<void> _generatePatientNumber() async {
    // Get all patients to find the highest patient number
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    await patientProvider.fetchPatients();
    final patients = patientProvider.patients;
    
    // Find the highest patient number
    int highestNumber = 0;
    
    for (var patient in patients) {
      if (patient.patientNumber != null && patient.patientNumber!.isNotEmpty) {
        try {
          // Remove any leading zeros before parsing to avoid octal interpretation
          String numberStr = patient.patientNumber!;
          while (numberStr.startsWith('0') && numberStr.length > 1) {
            numberStr = numberStr.substring(1);
          }
          
          // Parse as decimal (base 10) explicitly
          final number = int.parse(numberStr, radix: 10);
          if (number > highestNumber) {
            highestNumber = number;
          }
        } catch (e) {
          print('Error parsing patient number: ${patient.patientNumber} - $e');
          // If the patient number is not in the expected format, ignore it
        }
      }
    }
    
    // Next number is highest + 1, starting from 1 if no patients exist
    final nextNumber = highestNumber + 1;
    
    // Format the number as a string with leading zeros
    _patientNumber = nextNumber.toString().padLeft(6, '0');
    
    print('Generated patient number: $_patientNumber');

  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    
    // Dispose detailed medical history controllers
    _chronicDiseasesController.dispose();
    _surgicalHistoryController.dispose();
    _currentMedicationsController.dispose();
    _familyMedicalHistoryController.dispose();
    _socialHistoryController.dispose();
    _immunizationsController.dispose();
    _gynecologicalHistoryController.dispose();
    
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? initialDate;
    try {
      initialDate = _dateOfBirthController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text)
          : DateTime.now().subtract(const Duration(days: 365 * 30));
    } catch (e) {
      initialDate = DateTime.now().subtract(const Duration(days: 365 * 30));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }



  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    // Helper function to handle empty fields
    String handleEmptyField(String text) {
      return text.trim().isEmpty ? 'لا يوجد' : text.trim();
    }
    
    final patient = Patient(
      id: widget.patient?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirthController.text.trim(),
      bloodType: _bloodType,
      medicalHistory: handleEmptyField(_medicalHistoryController.text),
      allergies: handleEmptyField(_allergiesController.text),
      notes: handleEmptyField(_notesController.text),
      createdAt: widget.patient?.createdAt ?? formattedDate,
      patientNumber: _patientNumber,
      chronicDiseases: handleEmptyField(_chronicDiseasesController.text),
      surgicalHistory: handleEmptyField(_surgicalHistoryController.text),
      currentMedications: handleEmptyField(_currentMedicationsController.text),
      familyMedicalHistory: handleEmptyField(_familyMedicalHistoryController.text),
      socialHistory: handleEmptyField(_socialHistoryController.text),
      immunizations: handleEmptyField(_immunizationsController.text),
      gynecologicalHistory: _gender == 'أنثى' ? handleEmptyField(_gynecologicalHistoryController.text) : null,
    );

    bool success;
    if (widget.patient == null) { // Adding new patient
      // Get admin credentials for re-authentication
      final app_user.User? adminUserFromProvider = authProvider.currentUser;
      final String? adminEmail = adminUserFromProvider?.email;
      final String? adminUsername = adminUserFromProvider?.username;
      final String? adminPassword = adminUserFromProvider?.password; // Assuming this is the plain text password
      final String? adminAuthIdentifier = adminEmail ?? adminUsername; // Prefer email for auth
      final firebase_auth.User? originalFirebaseAdminUser = _auth.currentUser;

      if (adminAuthIdentifier == null || adminPassword == null || originalFirebaseAdminUser == null || adminUserFromProvider == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Admin credentials not found. Cannot securely add patient. Please re-login.')),
        );
        return;
      }

      // Add new patient - this will also create the Firebase Auth account and user document
      success = await patientProvider.addPatient(
        patient,
        adminAuthIdentifier: adminAuthIdentifier, // Corrected: Pass the identifier, remove '!'
        adminPassword: adminPassword,
        originalAdminAuthUserUid: originalFirebaseAdminUser.uid,
      );
      
      if (success) {
        print('Successfully added patient: ${patient.name}');
      }
    } else {
      // Update existing patient
      success = await patientProvider.updatePatient(patient);
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.patient == null
                ? 'تم إضافة المريض بنجاح'
                : 'تم تحديث بيانات المريض بنجاح',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.patient == null
                ? 'فشل في إضافة المريض'
                : 'فشل في تحديث بيانات المريض',
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
        title: Text(widget.patient == null ? 'إضافة مريض جديد' : 'تعديل بيانات المريض'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'الاسم',
                hint: 'أدخل اسم المريض',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المريض';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'رقم الهاتف',
                hint: 'أدخل رقم هاتف المريض',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال رقم هاتف المريض';
                  }
                  return null;
                },
              ),
              CustomTextField(
                label: 'العنوان',
                hint: 'أدخل عنوان المريض',
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال عنوان المريض';
                  }
                  return null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الجنس',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                        value: _gender,
                        isExpanded: true,
                        items: _genderOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _gender = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              CustomTextField(
                label: 'تاريخ الميلاد',
                hint: 'YYYY-MM-DD',
                controller: _dateOfBirthController,
                readOnly: true,
                onTap: () => _selectDate(context),
                suffixIcon: const Icon(Icons.calendar_today),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال تاريخ ميلاد المريض';
                  }
                  return null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فصيلة الدم',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                        value: _bloodType,
                        isExpanded: true,
                        items: _bloodTypeOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _bloodType = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              // Basic medical information
              Text(
                'معلومات طبية أساسية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'التاريخ الطبي',
                hint: 'أدخل التاريخ الطبي للمريض (اختياري)',
                controller: _medicalHistoryController,
                maxLines: 3,
              ),
              CustomTextField(
                label: 'الحساسية',
                hint: 'أدخل معلومات الحساسية للمريض (اختياري)',
                controller: _allergiesController,
                maxLines: 2,
              ),
              CustomTextField(
                label: 'ملاحظات',
                hint: 'أدخل ملاحظات إضافية (اختياري)',
                controller: _notesController,
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              // Detailed medical history section
              Text(
                'التاريخ المرضي التفصيلي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              // Chronic Diseases
              CustomTextField(
                label: 'الأمراض السابقة (المزمنة والحادة)',
                hint: 'مثل السكري، ارتفاع ضغط الدم، أمراض القلب، الربو، السرطان، إلخ',
                controller: _chronicDiseasesController,
                maxLines: 3,
              ),
              
              // Surgical History
              CustomTextField(
                label: 'العمليات الجراحية السابقة',
                hint: 'مثل استئصال الزائدة، عمليات القلب، جراحات العظام، إلخ',
                controller: _surgicalHistoryController,
                maxLines: 3,
              ),
              
              // Current Medications
              CustomTextField(
                label: 'الأدوية الحالية',
                hint: 'أسماء الأدوية والجرعات التي يتناولها المريض بانتظام',
                controller: _currentMedicationsController,
                maxLines: 3,
              ),
              
              // Family Medical History
              CustomTextField(
                label: 'التاريخ العائلي للأمراض',
                hint: 'أمراض وراثية أو أمراض شائعة في العائلة (مثل السكري، السرطان، أمراض القلب)',
                controller: _familyMedicalHistoryController,
                maxLines: 3,
              ),
              
              // Social History
              CustomTextField(
                label: 'التاريخ الاجتماعي',
                hint: 'نمط الحياة (تدخين، كحول، مخدرات)، الحالة الاجتماعية، المهنة',
                controller: _socialHistoryController,
                maxLines: 3,
              ),
              
              // Immunizations
              CustomTextField(
                label: 'اللقاحات',
                hint: 'اللقاحات التي تلقاها المريض وتواريخها',
                controller: _immunizationsController,
                maxLines: 2,
              ),
              
              // Gynecological History (only for females)
              if (_gender == 'أنثى')
                CustomTextField(
                  label: 'التاريخ النسائي',
                  hint: 'الدورة الشهرية، الحمل، الولادة، الإجهاض، إلخ',
                  controller: _gynecologicalHistoryController,
                  maxLines: 3,
                ),
              const SizedBox(height: 16),
              CustomButton(
                text: widget.patient == null ? 'إضافة مريض' : 'تحديث البيانات',
                onPressed: _savePatient,
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
}
