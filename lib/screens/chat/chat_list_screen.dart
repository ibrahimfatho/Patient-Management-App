import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_notifier.dart';
import '../../providers/patient_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late ChatNotifier _chatNotifier;
  late AuthProvider _authProvider;
  late User _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _chatNotifier = Provider.of<ChatNotifier>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = _authProvider.currentUser!;

    // Start listening to chat rooms
    _chatNotifier.listenToChatRooms(_currentUser.id!);
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ChatNotifier>(
              builder: (context, chatNotifier, child) {
                final chatRooms = chatNotifier.chatRooms;
                
                if (chatRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد محادثات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_currentUser.role == 'doctor')
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to patient list to start a new conversation
                              Navigator.pushNamed(context, '/patients');
                            },
                            child: const Text('بدء محادثة جديدة'),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    return _buildChatRoomTile(chatRooms[index]);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to appropriate screen based on user role
          if (_currentUser.role == 'doctor') {
            // Doctors navigate to patient list to start a new conversation
            Navigator.pushNamed(context, '/start_chat');
          } else {
            // Patients navigate to doctor list to start a new conversation
            _showDoctorSelectionDialog();
          }
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildChatRoomTile(Map<String, dynamic> chatRoom) {
    final String? currentUserAuthId = _currentUser.userId;

    if (currentUserAuthId == null || currentUserAuthId.isEmpty) {
      print('Error in _buildChatRoomTile: Current user Auth ID is null or empty.');
      return const ListTile(
        leading: CircleAvatar(child: Icon(Icons.error_outline, color: Colors.red)),
        title: Text('خطأ في تحميل معلومات المستخدم الحالي'),
        subtitle: Text('لا يمكن عرض هذه المحادثة.'),
      );
    }

    final List<dynamic> participants = chatRoom['participants'] as List<dynamic>; 
    final String otherUserId = participants.firstWhere(
      (id) => id != currentUserAuthId, 
      orElse: () => '',
    ) as String; 
    
    if (otherUserId.isEmpty) {
      print('Error in _buildChatRoomTile: Could not determine other user ID for chatRoom ${chatRoom['id']}. Participants: $participants, CurrentUserAuthId: $currentUserAuthId');
      return const SizedBox.shrink(); 
    }
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserDetails(otherUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('جاري التحميل...'),
          );
        }
        
        final userData = snapshot.data!;
        final String name = userData['name'] ?? 'مستخدم';
        final String? photoUrl = userData['photoUrl'];
        final lastMessage = chatRoom['lastMessage'] ?? '';
        final lastMessageTime = chatRoom['lastMessageTime'] as Timestamp?;
        final int unreadCount = chatRoom['unreadCount'] ?? 0;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            photoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: lastMessageTime != null
                ? Text(
                    _formatTimestamp(lastMessageTime),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  )
                : null,
            onTap: () async { // Make onTap async
              final String chatRoomId = chatRoom['id'] as String;
              // _currentUser.userId is already confirmed non-null/empty at the start of _buildChatRoomTile
              // otherUserId is also confirmed non-null/empty earlier in _buildChatRoomTile
              final String currentUserAuthIdForTap = _currentUser.userId!;

              // print('[ChatListScreen._buildChatRoomTile.onTap] Unmarking chat $chatRoomId for user $currentUserAuthIdForTap and other user $otherUserId');
              // final List<dynamic> deletedForList = List<dynamic>.from(chatRoom['deletedFor'] ?? []);
              // print('[ChatListScreen._buildChatRoomTile.onTap] Tapper (current user) Auth ID: $currentUserAuthIdForTap');
              // print('[ChatListScreen._buildChatRoomTile.onTap] Other user in chat Auth ID: $otherUserId');
              // print('[ChatListScreen._buildChatRoomTile.onTap] Current deletedFor list (from client chatRoom data): $deletedForList.');
              // print('[ChatListScreen._buildChatRoomTile.onTap] Attempting to unmark for tapper: $currentUserAuthIdForTap');

              // Unmark as deleted for the current user (tapping user)
              await _chatNotifier.unmarkChatAsDeletedForUser(chatRoomId, currentUserAuthIdForTap);
              
              // print('[ChatListScreen._buildChatRoomTile.onTap] Attempting to unmark for other user: $otherUserId');
              // Unmark as deleted for the other user in the chat
              print('[ChatListScreenState._startChatWithDoctor] Attempting to unmark for patient: $currentUserAuthIdForTap in room $chatRoomId');
              await _chatNotifier.unmarkChatAsDeletedForUser(chatRoomId, currentUserAuthIdForTap);

              if (!mounted) return;
              // Navigate to chat screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: chatRoomId, 
                    otherUserId: otherUserId,
                    otherUserName: name, // name is from FutureBuilder snapshot
                    otherUserPhotoUrl: photoUrl, // photoUrl is from FutureBuilder snapshot
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    // Check if the user is a patient or a doctor
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final patientProvider = Provider.of<PatientProvider>(context, listen: false);
    
    try {
      // First check if it's a doctor/staff (in users collection)
      final user = await userProvider.getUserById(userId);
      if (user != null) {
        return {
          'name': user.name,
          'photoUrl': user.photoUrl,
          'role': user.role,
        };
      }
      
      // If not found in users, check patients collection
      final patient = await patientProvider.getPatientById(userId);
      if (patient != null) {
        return {
          'name': patient.name,
          'photoUrl': null, // Patients might not have photos in your system
          'role': 'patient',
        };
      }
      
      // Default if not found
      return {
        'name': 'مستخدم غير معروف',
        'photoUrl': null,
        'role': 'unknown',
      };
    } catch (e) {
      debugPrint('Error getting user details: $e');
      return {
        'name': 'مستخدم غير معروف',
        'photoUrl': null,
        'role': 'unknown',
      };
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 7) {
      // If older than a week, show the date
      return DateFormat.yMd().format(messageTime);
    } else if (difference.inDays > 0) {
      // If older than a day but less than a week, show the day name
      return DateFormat.E().format(messageTime);
    } else {
      // If today, show the time
      return DateFormat.jm().format(messageTime);
    }
  }
  
  // Show dialog for patients to select a doctor to chat with
  void _showDoctorSelectionDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // For patient users, we need to get their patientId
      String? patientId;
      if (_currentUser.role == 'patient') {
        // If the user has a direct patientId reference
        if (_currentUser.patientId != null && _currentUser.patientId!.isNotEmpty) {
          patientId = _currentUser.patientId;
        } else {
          // Otherwise, we need to find the patient by user ID
          patientId = _currentUser.id;
        }
      }
      
      if (patientId == null) {
        // Close loading dialog
        Navigator.pop(context);
        _showErrorSnackBar('لم يتم العثور على معلومات المريض');
        return;
      }
      
      // Get patient's appointments
      await appointmentProvider.fetchPatientAppointments(patientId);
      final appointments = appointmentProvider.appointments;
      
      // Extract doctor IDs from appointments
      final doctorIdsWithAppointments = appointments.map((appointment) => appointment.doctorId).toSet().toList();
      
      // Get all doctors
      final allDoctors = await userProvider.getAllDoctors();
      
      // Filter doctors to only those with appointments with this patient
      final doctorsWithAppointments = allDoctors.where(
        (doctor) => doctorIdsWithAppointments.contains(doctor.id)
      ).toList();
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (doctorsWithAppointments.isEmpty) {
        _showErrorSnackBar('لا يوجد أطباء متاحين حالياً');
        return;
      }
      
      // Show doctor selection dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اختر طبيب للمحادثة'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: doctorsWithAppointments.length,
              itemBuilder: (context, index) {
                final doctor = doctorsWithAppointments[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              doctor.photoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                doctor.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            doctor.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(doctor.name),
                  subtitle: Text(doctor.specialization ?? 'طبيب'),
                  onTap: () {
                    Navigator.pop(context);
                    _startChatWithDoctor(doctor);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('حدث خطأ أثناء تحميل قائمة الأطباء');
    }
  }
  
  // Start chat with selected doctor
  Future<void> _startChatWithDoctor(User doctor) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final String? currentPatientAuthUid = _currentUser.userId;
      final String? selectedDoctorAuthUid = doctor.userId;

      if (currentPatientAuthUid == null || currentPatientAuthUid.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('خطأ: معرف المريض الحالي غير صالح.');
        print('[_ChatListScreenState._startChatWithDoctor] Error: Current patient Auth UID is null or empty.');
        return;
      }

      if (selectedDoctorAuthUid == null || selectedDoctorAuthUid.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('خطأ: معرف الطبيب المحدد غير صالح.');
        print('[_ChatListScreenState._startChatWithDoctor] Error: Selected doctor Auth UID is null or empty.');
        return;
      }

      print('[ChatListScreenState._startChatWithDoctor] Initializing chat. Patient AuthUID: $currentPatientAuthUid, Doctor AuthUID: $selectedDoctorAuthUid');
      final chatRoomId = await _chatNotifier.initializeChat(currentPatientAuthUid, selectedDoctorAuthUid);

      // Close loading dialog
      Navigator.pop(context);
      
    if (chatRoomId.isNotEmpty) {
        await _chatNotifier.unmarkChatAsDeletedForUser(chatRoomId, currentPatientAuthUid);
        await _chatNotifier.unmarkChatAsDeletedForUser(chatRoomId, selectedDoctorAuthUid);


        // Navigate to chat screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: selectedDoctorAuthUid, // Pass doctor's Auth UID
              otherUserName: doctor.name,
              otherUserPhotoUrl: doctor.photoUrl,
              chatRoomId: chatRoomId,
            ),
          ),
        );

      } else {
        _showErrorSnackBar('فشل في إنشاء المحادثة');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showErrorSnackBar('حدث خطأ أثناء إنشاء المحادثة');
    }
  }
  
  // This method has been replaced by using ChatNotifier.initializeChat which handles checking for existing chats internally
  
  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
