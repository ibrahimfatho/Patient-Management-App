import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/chat_notifier.dart';
import '../../models/patient_model.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class StartChatScreen extends StatefulWidget {
  const StartChatScreen({Key? key}) : super(key: key);

  @override
  State<StartChatScreen> createState() => _StartChatScreenState();
}

class _StartChatScreenState extends State<StartChatScreen> {
  late PatientProvider _patientProvider;
  late AuthProvider _authProvider;
  late AppointmentProvider _appointmentProvider;
  late ChatNotifier _chatNotifier;
  late User _currentUser;
  List<Patient> _patients = [];
  List<String> _patientIdsWithAppointments = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _patientProvider = Provider.of<PatientProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    _chatNotifier = Provider.of<ChatNotifier>(context, listen: false);
    _currentUser = _authProvider.currentUser!;

    // Load patients with appointments
    await _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get doctor's appointments
      await _appointmentProvider.fetchDoctorAppointments(_currentUser.id!);
      final appointments = _appointmentProvider.appointments;
      
      // Extract patient IDs from appointments
      _patientIdsWithAppointments = appointments.map((appointment) => appointment.patientId).toSet().toList();
      
      // Get patients with appointments
      final allPatients = await _patientProvider.getAllPatients();
      final patientsWithAppointments = allPatients.where(
        (patient) => _patientIdsWithAppointments.contains(patient.id)
      ).toList();
      
      setState(() {
        _patients = patientsWithAppointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل قائمة المرضى');
    }
  }

  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) {
      return _patients;
    }
    
    return _patients.where((patient) {
      final name = patient.name.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بدء محادثة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث عن مريض...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا يوجد مرضى',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = _filteredPatients[index];
                          return _buildPatientTile(patient);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTile(Patient patient) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          patient.phone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _startChat(patient),
      ),
    );
  }

  Future<void> _startChat(Patient selectedPatient) async {
    if (!mounted) return;
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Ensure the current doctor's Auth UID is available
      final currentDoctorAuthUid = _currentUser.userId; 
      if (currentDoctorAuthUid == null) {
        throw Exception('Current doctor Auth UID is null.');
      }

      // Fetch the User object for the selected patient to get their Auth UID
      final patientUser = await _authProvider.getUserByPatientId(selectedPatient.id!); // patient.id is the patientId
      
      if (patientUser == null || patientUser.userId == null) {
        throw Exception('Could not find user details or Auth UID for the selected patient.');
      }
      final patientAuthUid = patientUser.userId!;

      // Initialize chat using Auth UIDs for both doctor and patient
      final String chatRoomId = await _chatNotifier.initializeChat(
        currentDoctorAuthUid,
        patientAuthUid, 
      );

      // Ensure the current user (doctor) is not marked as deleted for this chat
      await _chatNotifier.unmarkChatAsDeletedForUser(chatRoomId, currentDoctorAuthUid);
      // Also ensure the patient is not marked as deleted for this chat, making it active for both
      await _chatNotifier.unmarkChatAsDeletedForUser(chatRoomId, patientAuthUid);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatRoomId: chatRoomId,
              otherUserName: selectedPatient.name, 
              otherUserId: patientAuthUid,      
              otherUserPhotoUrl: null, 
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog
        _showErrorSnackBar('حدث خطأ أثناء بدء المحادثة: ${e.toString()}');
      }
      print('Error starting chat: $e');
    }
  }
  
  // This method has been replaced by using ChatNotifier.initializeChat which handles checking for existing chats internally
}
