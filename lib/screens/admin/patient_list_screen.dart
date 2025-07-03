import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/enhanced_list_view.dart';
import '../../widgets/loading_indicator.dart';
import 'add_edit_patient_screen.dart';
import 'patient_details_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  // Filtering options
  String? _selectedGender;
  String? _selectedBloodType;
  RangeValues _ageRange = const RangeValues(0, 100);
  bool _isFilterMenuOpen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PatientProvider>(context, listen: false).fetchPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchPatients() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      Provider.of<PatientProvider>(
        context,
        listen: false,
      ).searchPatients(_searchController.text.trim()).then((_) {
        setState(() {
          _isSearching = false;
        });
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    Provider.of<PatientProvider>(context, listen: false).fetchPatients();
  }

  void _clearFilters() {
    setState(() {
      _selectedGender = null;
      _selectedBloodType = null;
      _ageRange = const RangeValues(0, 100);
    });
    Provider.of<PatientProvider>(context, listen: false).fetchPatients();
  }

  void _applyFilters() {
    final patients =
        Provider.of<PatientProvider>(context, listen: false).patients;
    final now = DateTime.now();

    // Apply filters
    final filteredPatients =
        patients.where((patient) {
          // Gender filter
          if (_selectedGender != null && patient.gender != _selectedGender) {
            return false;
          }

          // Blood type filter
          if (_selectedBloodType != null &&
              patient.bloodType != _selectedBloodType) {
            return false;
          }

          // Age filter
          try {
            final birthDate = DateTime.parse(patient.dateOfBirth);
            final age =
                now.year -
                birthDate.year -
                (now.month < birthDate.month ||
                        (now.month == birthDate.month &&
                            now.day < birthDate.day)
                    ? 1
                    : 0);

            if (age < _ageRange.start || age > _ageRange.end) {
              return false;
            }
          } catch (e) {
            // Skip invalid dates
          }

          return true;
        }).toList();

    // Update the provider with filtered results
    Provider.of<PatientProvider>(
      context,
      listen: false,
    ).setFilteredPatients(filteredPatients);
  }

  Widget _buildFilterOptions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'خيارات التصفية',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('مسح الكل'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الجنس'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                        DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      hint: const Text('اختر'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('فصيلة الدم'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'A+', child: Text('A+')),
                        DropdownMenuItem(value: 'A-', child: Text('A-')),
                        DropdownMenuItem(value: 'B+', child: Text('B+')),
                        DropdownMenuItem(value: 'B-', child: Text('B-')),
                        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                        DropdownMenuItem(value: 'O+', child: Text('O+')),
                        DropdownMenuItem(value: 'O-', child: Text('O-')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodType = value;
                        });
                      },
                      hint: const Text('اختر'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'العمر: ${_ageRange.start.round()} - ${_ageRange.end.round()} سنة',
              ),
              RangeSlider(
                values: _ageRange,
                min: 0,
                max: 100,
                divisions: 100,
                labels: RangeLabels(
                  '${_ageRange.start.round()}',
                  '${_ageRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _ageRange = values;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'تطبيق التصفية',
              onPressed: _applyFilters,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف المريض ${patient.name}؟'),
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
                  Provider.of<PatientProvider>(
                    context,
                    listen: false,
                  ).deletePatient(patient.id!).then((success) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم حذف المريض بنجاح'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('فشل في حذف المريض'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'البحث عن مريض...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _clearSearch();
                          }
                        },
                        onSubmitted: (_) => _searchPatients(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomButton(
                      text: 'بحث',
                      onPressed: _searchPatients,
                      isLoading: _isSearching,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color:
                            _isFilterMenuOpen ||
                                    _selectedGender != null ||
                                    _selectedBloodType != null
                                ? AppTheme.primaryColor
                                : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isFilterMenuOpen = !_isFilterMenuOpen;
                        });
                      },
                      tooltip: 'تصفية النتائج',
                    ),
                  ],
                ),
                if (_isFilterMenuOpen) _buildFilterOptions(),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PatientProvider>(
              builder: (ctx, patientProvider, child) {
                // Create patient list items
                final patients = patientProvider.patients;
                final patientItems =
                    patients.map((patient) {
                      // Create detail items for the patient
                      final details = [
                        DetailItem(text: 'الجنس : ${patient.gender}'),
                        DetailItem(text: 'فصيلة الدم : ${patient.bloodType}'),
                        DetailItem(
                          text:
                              'العمر : ${_calculateAge(patient.dateOfBirth)} سنة',
                        ),
                      ];

                      return EnhancedListItem(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: AppTheme.primaryColor.withOpacity(
                            0.1,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),

                        title: Text(
                          patient.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          'رقم الهاتف: ${patient.phone}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        details: details,
                        trailing: PopupMenuButton(
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('عرض'),
                                    ],
                                  ),
                                ),
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
                                      Text(
                                        'حذف',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PatientDetailsScreen(
                                          patientId: patient.id!,
                                        ),
                                  ),
                                );
                                break;
                              case 'edit':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => AddEditPatientScreen(
                                          patient: patient,
                                        ),
                                  ),
                                );
                                break;
                              case 'delete':
                                _showDeleteConfirmation(context, patient);
                                break;
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => PatientDetailsScreen(
                                    patientId: patient.id!,
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
                      const Icon(
                        Icons.person_off,
                        color: Colors.grey,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'لا توجد نتائج للبحث'
                            : 'لا يوجد مرضى حالياً',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );

                return EnhancedListView(
                  children: patientItems,
                  isLoading: patientProvider.isLoading,
                  errorMessage: patientProvider.error,
                  onRetry: () => patientProvider.fetchPatients(),
                  emptyStateWidget: emptyStateWidget,
                  loadingWidget: const LoadingIndicator(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditPatientScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
