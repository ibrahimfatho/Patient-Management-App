import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'chats';

  // Create a new chat room or get existing one between two users
  Future<String> getChatRoomId(String userId1, String userId2) async {
    // Sort IDs to ensure consistent chat room ID regardless of who initiates
    final List<String> ids = [userId1, userId2]..sort();
    final String chatRoomId = '${ids[0]}_${ids[1]}';
    
    // Check if chat room exists
    final chatRoom = await _firestore.collection(_collectionName).doc(chatRoomId).get();
    
    // If it doesn't exist, create it
    if (!chatRoom.exists) {
      print('[ChatService.getChatRoomId] Creating new chat room $chatRoomId with participants: [$userId1, $userId2]');
      await _firestore.collection(_collectionName).doc(chatRoomId).set({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
        'deletedFor': [], // Track which users have deleted this chat
        'unreadCount': {}, // Track unread messages for each user
      });
    } else {
      // If the chat exists but doesn't have the deletedFor field, add it
      if (!chatRoom.data()!.containsKey('deletedFor')) {
        await _firestore.collection(_collectionName).doc(chatRoomId).update({
          'deletedFor': [],
        });
      }
    }
    
    return chatRoomId;
  }
  
  // Check if a chat room already exists between two users
  Future<String?> checkExistingChatRoom(String userId1, String userId2) async {
    // Sort IDs to ensure consistent chat room ID format
    final List<String> ids = [userId1, userId2]..sort();
    final String expectedChatRoomId = '${ids[0]}_${ids[1]}';
    
    // Check if the chat room exists
    final chatRoom = await _firestore.collection(_collectionName).doc(expectedChatRoomId).get();
    
    if (chatRoom.exists) {
      return expectedChatRoomId;
    }
    
    return null;
  }

  // Send a message to a chat room
  Future<void> sendMessage(String chatRoomId, types.Message message, String senderId) async {
    // Get chat room data to check participants
    final chatRoomDoc = await _firestore.collection(_collectionName).doc(chatRoomId).get();
    final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>?;
    
    if (chatRoomData != null) {
      final List<dynamic> participants = chatRoomData['participants'] ?? [];
      Map<String, dynamic> unreadCount = chatRoomData['unreadCount'] as Map<String, dynamic>? ?? {};
      
      // Increment unread count for all participants except the sender
      for (final participantId in participants) {
        if (participantId != senderId) {
          final currentCount = unreadCount[participantId] as int? ?? 0;
          unreadCount[participantId] = currentCount + 1;
        }
      }
      
      List<dynamic> updatedDeletedFor = List<dynamic>.from(chatRoomData['deletedFor'] ?? []);
      bool deletedForWasModified = false;

      // Ensure chat is not marked as deleted for recipients
      for (final participantId in participants) {
        if (participantId != senderId && updatedDeletedFor.contains(participantId)) {
          updatedDeletedFor.remove(participantId);
          deletedForWasModified = true;
          print('[ChatService.sendMessage] Un-deleting chat for recipient $participantId in room $chatRoomId due to new message.');
        }
      }

      // Add message to the messages subcollection
      await _firestore
          .collection(_collectionName)
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toJson());
      
      // Update chat room with last message info and unread counts
      await _firestore.collection(_collectionName).doc(chatRoomId).update({
        'lastMessage': message.type == types.MessageType.text
            ? (message as types.TextMessage).text
            : 'Attachment',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': unreadCount,
        if (deletedForWasModified) 'deletedFor': updatedDeletedFor,
      });
    }
  }

  // Mark a chat as deleted for a specific user
  Future<bool> markChatAsDeletedForUser(String chatRoomId, String userId) async {
    try {
      final chatRoomDoc = await _firestore.collection(_collectionName).doc(chatRoomId).get();
      
      if (chatRoomDoc.exists) {
        final data = chatRoomDoc.data() as Map<String, dynamic>;
        List<dynamic> deletedFor = data['deletedFor'] ?? [];
        
        // Add the user to the deletedFor list if not already there
        if (!deletedFor.contains(userId)) {
          deletedFor.add(userId);
          
          await _firestore.collection(_collectionName).doc(chatRoomId).update({
            'deletedFor': deletedFor,
          });
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error marking chat as deleted: $e');
      return false;
    }
  }

  // Unmark a chat as deleted for a specific user (make it visible again)
  Future<bool> unmarkChatAsDeletedForUser(String chatRoomId, String userId) async {
    if (userId.isEmpty) { // Prevent trying to remove an empty string
      print('[ChatService.unmarkChatAsDeletedForUser] Error: userId is empty for chatRoomId $chatRoomId. Skipping unmark.');
      return false;
    }
    try {
      // It's better to check if the document exists before attempting an update 
      // if there's a chance it might not, though arrayRemove itself is safe.
      // For simplicity here, we'll proceed directly with the update.
      // If chatRoomDoc.exists check is critical, it should be added back.

      await _firestore.collection(_collectionName).doc(chatRoomId).update({
        'deletedFor': FieldValue.arrayRemove([userId]), // Use arrayRemove
      });
      print('[ChatService.unmarkChatAsDeletedForUser] Attempted to unmark chat $chatRoomId for user $userId using arrayRemove.');
      return true;
    } catch (e) {
      print('[ChatService.unmarkChatAsDeletedForUser] Error unmarking chat $chatRoomId for user $userId: $e');
      return false;
    }
  }
  
  // Reset unread message count for a user
  Future<bool> resetUnreadCount(String chatRoomId, String userId) async {
    try {
      final chatRoomDoc = await _firestore.collection(_collectionName).doc(chatRoomId).get();
      
      if (chatRoomDoc.exists) {
        final data = chatRoomDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> unreadCount = data['unreadCount'] as Map<String, dynamic>? ?? {};
        
        // Reset unread count for this user
        unreadCount[userId] = 0;
        
        await _firestore.collection(_collectionName).doc(chatRoomId).update({
          'unreadCount': unreadCount,
        });
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error resetting unread count: $e');
      return false;
    }
  }
  
  // Get messages stream
  Stream<List<types.Message>> getMessages(String chatRoomId) {
    return _firestore
        .collection(_collectionName)
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            // Convert Firestore timestamp to DateTime
            if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp).toDate().millisecondsSinceEpoch;
            }
            return types.Message.fromJson(data);
          }).toList();
        });
  }

  // Create a text message
  types.TextMessage createTextMessage({
    required String text,
    required types.User user,
  }) {
    final uuid = const Uuid();
    return types.TextMessage(
      id: uuid.v4(),
      author: user,
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Get all chat rooms for a user (either doctor or patient)
  Stream<QuerySnapshot> getChatRooms(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('participants', arrayContains: userId)
        .snapshots();
  }
  
  // Check if a chat is deleted for a specific user
  Future<bool> isChatDeletedForUser(String chatRoomId, String userId) async {
    try {
      final chatRoom = await _firestore.collection(_collectionName).doc(chatRoomId).get();
      
      if (!chatRoom.exists) {
        return false;
      }
      
      // Check if the deletedFor field exists and contains the userId
      if (chatRoom.data()!.containsKey('deletedFor')) {
        List<dynamic> deletedFor = List<dynamic>.from(chatRoom.data()!['deletedFor']);
        return deletedFor.contains(userId);
      }
      
      return false;
    } catch (e) {
      print('Error checking if chat is deleted: $e');
      return false;
    }
  }

  // Mark all messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    final messagesQuery = await _firestore
        .collection(_collectionName)
        .doc(chatRoomId)
        .collection('messages')
        .where('authorId', isNotEqualTo: userId)
        .where('status', isEqualTo: 'sent')
        .get();
    
    final batch = _firestore.batch();
    for (final doc in messagesQuery.docs) {
      batch.update(doc.reference, {'status': 'seen'});
    }
    
    await batch.commit();
  }
}
