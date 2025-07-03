import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/patient_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import 'patient_change_password_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({Key? key}) : super(key: key);

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  Future<Patient?>? _patientFuture;

  @override
  void initState() {
    super.initState();
    // Defer future creation until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final patientProvider = Provider.of<PatientProvider>(
          context,
          listen: false,
        );
        setState(() {
          _patientFuture = patientProvider.getPatientByPhone(
            authProvider.currentUser!.username,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Patient?>(
        future: _patientFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              user == null) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
                    'لم يتم العثور على بيانات المريض: ${snapshot.error ?? 'بيانات غير متاحة'}',
                    style: const TextStyle(color: AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final patient = snapshot.data!;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ), // Adjust space for solid app bar
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primaryColor,
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                                size: 50,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            patient.name,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'رقم المريض: ${patient.patientNumber ?? 'غير محدد'}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryColor.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          text: 'تغيير كلمة المرور',
                          icon: Icons.password,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => const PatientChangePasswordScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'المعلومات الشخصية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildEnhancedInfoRow(
                              context,
                              'الاسم الكامل',
                              patient.name,
                              Icons.person_outline,
                              AppTheme.primaryColor,
                            ),
                            const Divider(height: 24),
                            _buildEnhancedInfoRow(
                              context,
                              'رقم الهاتف',
                              patient.phone,
                              Icons.phone_outlined,
                              AppTheme.primaryColor,
                            ),
                            const Divider(height: 24),

                            _buildEnhancedInfoRow(
                              context,
                              'العنوان',
                              patient.address,
                              Icons.location_on_outlined,
                              AppTheme.primaryColor,
                            ),
                            const Divider(height: 24),
                            _buildEnhancedInfoRow(
                              context,
                              'الجنس',
                              patient.gender,
                              Icons.wc_outlined,
                              AppTheme.primaryColor,
                            ),
                            const Divider(height: 24),
                            _buildEnhancedInfoRow(
                              context,
                              'تاريخ الميلاد',
                              patient.dateOfBirth,
                              Icons.cake_outlined,
                              AppTheme.primaryColor,
                            ),
                            const Divider(height: 24),
                            _buildEnhancedInfoRow(
                              context,
                              'فصيلة الدم',
                              patient.bloodType,
                              Icons.bloodtype_outlined,
                              AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'المعلومات الطبية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            if (patient.medicalHistory?.isNotEmpty == true)
                              _buildEnhancedInfoRow(
                                context,
                                'التاريخ الطبي',
                                patient.medicalHistory!,
                                Icons.history_edu_outlined,
                                AppTheme.primaryColor,
                              ),
                            if (patient.allergies?.isNotEmpty == true) ...[
                              const Divider(height: 24),
                              _buildEnhancedInfoRow(
                                context,
                                'الحساسية',
                                patient.allergies!,
                                Icons.warning_amber_outlined,
                                AppTheme.primaryColor,
                              ),
                            ],
                            if (patient.chronicDiseases?.isNotEmpty ==
                                true) ...[
                              const Divider(height: 24),
                              _buildEnhancedInfoRow(
                                context,
                                'الأمراض المزمنة',
                                patient.chronicDiseases!,
                                Icons.coronavirus_outlined,
                                AppTheme.primaryColor,
                              ),
                            ],
                            if (patient.currentMedications?.isNotEmpty ==
                                true) ...[
                              const Divider(height: 24),
                              _buildEnhancedInfoRow(
                                context,
                                'الأدوية الحالية',
                                patient.currentMedications!,
                                Icons.medication_liquid_outlined,
                                AppTheme.primaryColor,
                              ),
                            ],
                            if (patient.surgicalHistory?.isNotEmpty ==
                                true) ...[
                              const Divider(height: 24),
                              _buildEnhancedInfoRow(
                                context,
                                'العمليات الجراحية',
                                patient.surgicalHistory!,
                                Icons.healing_outlined,
                                AppTheme.primaryColor,
                              ),
                            ],
                            if (patient.medicalHistory?.isEmpty != false &&
                                patient.allergies?.isEmpty != false &&
                                patient.chronicDiseases?.isEmpty != false &&
                                patient.currentMedications?.isEmpty != false &&
                                patient.surgicalHistory?.isEmpty != false)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text(
                                    'لا توجد معلومات طبية مسجلة',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
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
        ),
      ],
    );
  }
}
