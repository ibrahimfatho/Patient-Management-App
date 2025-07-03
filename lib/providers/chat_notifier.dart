import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import '../services/chat_service.dart';

import 'dart:async';

class ChatNotifier extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  List<types.Message> _messages = [];
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String _currentChatRoomId = '';
  String _currentUserId = '';
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;

  // Getters
  List<types.Message> get messages => _messages;
  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String get currentChatRoomId => _currentChatRoomId;
  
  // Get total unread message count across all chat rooms
  int getTotalUnreadCount() {
    int total = 0;
    for (final chatRoom in _chatRooms) {
      total += chatRoom['unreadCount'] as int? ?? 0;
    }
    return total;
  }

  // Initialize chat between doctor and patient
  Future<String> initializeChat(String userId1, String userId2) async { // Renamed params for clarity
    print('[ChatNotifier.initializeChat] Initializing chat between: $userId1 and $userId2');
    _setLoading(true);
    try {
      // First check if a chat room already exists
      final existingChatRoomId = await _chatService.checkExistingChatRoom(userId1, userId2);
      
      // If a chat room exists, use it
      if (existingChatRoomId != null) {
        _currentChatRoomId = existingChatRoomId;
        notifyListeners();
        return existingChatRoomId;
      }
      
      // Otherwise create a new chat room
      final chatRoomId = await _chatService.getChatRoomId(userId1, userId2);
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

  // Wrapper for ChatService.getChatRoomId
  Future<String> getChatRoomId(String userId1, String userId2) async {
    try {
      return await _chatService.getChatRoomId(userId1, userId2);
    } catch (e) {
      debugPrint('Error in ChatNotifier.getChatRoomId: $e');
      rethrow; // Or return an empty string/handle error as appropriate
    }
  }

  // Wrapper for ChatService.unmarkChatAsDeletedForUser
  Future<bool> unmarkChatAsDeletedForUser(String chatRoomId, String userId) async {
    try {
      return await _chatService.unmarkChatAsDeletedForUser(chatRoomId, userId);
    } catch (e) {
      debugPrint('Error in ChatNotifier.unmarkChatAsDeletedForUser: $e');
      return false;
    }
  }
  
  // Check if a chat room already exists between two users
  Future<String?> checkExistingChat(String userId1, String userId2) async {
    try {
      return await _chatService.checkExistingChatRoom(userId1, userId2);
    } catch (e) {
      debugPrint('Error checking existing chat: $e');
      return null;
    }
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

  // Delete a chat for a specific user
  Future<bool> deleteChatForUser(String chatRoomId, String userId) async {
    _setLoading(true);
    try {
      final success = await _chatService.markChatAsDeletedForUser(chatRoomId, userId);
      if (success) {
        // Refresh the chat rooms list to reflect the change
        listenToChatRooms(userId);
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Get chat rooms for a user
  Future<void> listenToChatRooms(String userId) async {
    _setLoading(true);
    _currentUserId = userId; // Store the current user ID
    debugPrint('[ChatNotifier] Listening to chat rooms for user: $userId');

    await _chatRoomsSubscription?.cancel(); // Cancel any existing subscription
    final completer = Completer<void>();

    _chatRoomsSubscription = _chatService.getChatRooms(userId).listen(
      (snapshot) async {
        await _processChatRooms(snapshot);
        if (!completer.isCompleted) {
          completer.complete();
        }
        // Set loading to false after the first batch or subsequent updates
        // We might want to set loading to false only once after the first fetch in prefetch scenario
        if (_isLoading) _setLoading(false); 
      },
      onError: (error) {
        debugPrint('[ChatNotifier] Error listening to chat rooms: $error');
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        _setLoading(false);
      },
      onDone: () {
        debugPrint('[ChatNotifier] Chat rooms stream closed for user: $userId');
        _setLoading(false);
      }
    );
    return completer.future; // This allows AuthProvider to await the first load
  }

  // Initialize and listen to chat rooms - called during pre-fetch
  Future<void> initAndListenToChatRooms(String userId) async {
    if (userId.isEmpty) {
      debugPrint('[ChatNotifier.initAndListenToChatRooms] User ID is empty, cannot listen to rooms.');
      return;
    }
    _currentUserId = userId; // Ensure currentUserId is set before listening
    return listenToChatRooms(userId);
  }

  // Process chat rooms data
  Future<void> _processChatRooms(QuerySnapshot snapshot) async {
    _chatRooms = [];
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participants'] ?? [];
      
      // Skip chats that have been marked as deleted for the current user
      if (data.containsKey('deletedFor')) {
        final List<dynamic> deletedFor = data['deletedFor'] ?? [];
        if (deletedFor.contains(_currentUserId)) {
          continue; // Skip this chat room
        }
      }
      
      // Get unread messages count
      int unreadCount = 0;
      if (data.containsKey('unreadCount') && 
          data['unreadCount'] is Map<String, dynamic>) {
        final unreadCountMap = data['unreadCount'] as Map<String, dynamic>;
        if (unreadCountMap.containsKey(_currentUserId)) {
          unreadCount = unreadCountMap[_currentUserId] ?? 0;
        }
      }
      
      // Get user details for each participant
      final Map<String, dynamic> chatRoom = {
        'id': doc.id,
        'participants': participants,
        'lastMessage': data['lastMessage'],
        'lastMessageTime': data['lastMessageTime'],
        'unreadCount': unreadCount,
        'participantDetails': <String, dynamic>{},
      };
      
      // Add to list
      _chatRooms.add(chatRoom);
    }
    
    // Sort chat rooms by most recent message time
    _chatRooms.sort((a, b) {
      final aTime = a['lastMessageTime'] as Timestamp?;
      final bTime = b['lastMessageTime'] as Timestamp?;
      
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      
      return bTime.compareTo(aTime); // Descending order (newest first)
    });
    
    notifyListeners();
  }

  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }

  // Mark messages as read and reset unread count
  Future<void> markMessagesAsRead() async {
    if (_currentChatRoomId.isEmpty || _currentUserId.isEmpty) return;
    
    try {
      await _chatService.resetUnreadCount(_currentChatRoomId, _currentUserId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }
}
