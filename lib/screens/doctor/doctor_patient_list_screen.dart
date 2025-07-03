import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import 'patient_medical_file_screen.dart';

class DoctorPatientListScreen extends StatefulWidget {
  const DoctorPatientListScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPatientListScreen> createState() => _DoctorPatientListScreenState();
}

class _DoctorPatientListScreenState extends State<DoctorPatientListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        // Fetch only patients assigned to this doctor
        Provider.of<PatientProvider>(context, listen: false).fetchDoctorPatients(user.id!);
      }
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
      Provider.of<PatientProvider>(context, listen: false)
          .searchPatients(_searchController.text.trim())
          .then((_) {
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

  int _calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final currentDate = DateTime.now();
      int age = currentDate.year - birthDate.year;
      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث عن مريض...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
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
              ],
            ),
          ),
          Expanded(
            child: Consumer<PatientProvider>(
              builder: (ctx, patientProvider, child) {
                if (patientProvider.isLoading) {
                  return const LoadingIndicator();
                }

                if (patientProvider.error != null) {
                  return Center(
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
                          'حدث خطأ: ${patientProvider.error}',
                          style: const TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'إعادة المحاولة',
                          onPressed: () {
                            patientProvider.fetchPatients();
                          },
                        ),
                      ],
                    ),
                  );
                }

                final patients = patientProvider.patients;
                if (patients.isEmpty) {
                  return Center(
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
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  itemBuilder: (ctx, index) {
                    final patient = patients[index];
                    return CustomCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatientMedicalFileScreen(patientId: patient.id!),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'رقم الهاتف: ${patient.phone}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppTheme.secondaryTextColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الجنس: ${patient.gender}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'فصيلة الدم: ${patient.bloodType}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'العمر: ${_calculateAge(patient.dateOfBirth)} سنة',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
