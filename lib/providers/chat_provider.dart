import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/chat_service.dart';

// No need for a ChatProvider class, we'll use ChatNotifier directly with ChangeNotifierProvider

class ChatNotifier extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<types.Message> _messages = [];
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String _currentChatRoomId = '';

  // Getters
  List<types.Message> get messages => _messages;
  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String get currentChatRoomId => _currentChatRoomId;
  
  // Current user ID for chat operations
  String _currentUserId = '';

  // Initialize chat between doctor and patient
  Future<String> initializeChat(String doctorId, String patientId) async {
    _setLoading(true);
    try {
      // Store the current user ID (doctor in this case)
      _currentUserId = doctorId;
      
      final chatRoomId = await _chatService.getChatRoomId(doctorId, patientId);
      _currentChatRoomId = chatRoomId;
      notifyListeners();
      return chatRoomId;
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      return '';
    } finally {
      _setLoading(false);
    }
  }
  
  // Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Send a message
  Future<void> sendMessage(types.Message message) async {
    if (_currentChatRoomId.isEmpty || _currentUserId.isEmpty) return;
    
    try {
      await _chatService.sendMessage(_currentChatRoomId, message, _currentUserId);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // Create a text message
  types.TextMessage createTextMessage({
    required String text,
    required types.User user,
  }) {
    return _chatService.createTextMessage(text: text, user: user);
  }

  // Listen to messages
  void listenToMessages(String chatRoomId) {
    _currentChatRoomId = chatRoomId;
    _chatService.getMessages(chatRoomId).listen((updatedMessages) {
      _messages = updatedMessages;
      notifyListeners();
    });
  }

  // Get chat rooms for a user
  void listenToChatRooms(String userId) {
    _chatService.getChatRooms(userId).listen((snapshot) {
      _processChatRooms(snapshot);
    });
  }

  // Process chat rooms data
  Future<void> _processChatRooms(QuerySnapshot snapshot) async {
    _chatRooms = [];
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participants'] ?? [];
      
      // Get user details for each participant
      final Map<String, dynamic> chatRoom = {
        'id': doc.id,
        'participants': participants,
        'lastMessage': data['lastMessage'],
        'lastMessageTime': data['lastMessageTime'],
        'participantDetails': <String, dynamic>{},
      };
      
      // Add to list
      _chatRooms.add(chatRoom);
    }
    
    notifyListeners();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String userId) async {
    if (_currentChatRoomId.isEmpty) return;
    
    try {
      await _chatService.markMessagesAsRead(_currentChatRoomId, userId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
