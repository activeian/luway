import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'notification_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String? carPlateNumber,
    String? carBrand,
  }) async {
    final chatMessage = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      carPlateNumber: carPlateNumber,
      carBrand: carBrand,
    );

    // Create or get conversation ID
    final conversationId = _getConversationId(senderId, receiverId);

    // Add message to messages subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(chatMessage.toJson());

    // Update conversation metadata
    await _firestore.collection('conversations').doc(conversationId).set({
      'participants': [senderId, receiverId],
      'lastMessage': message,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'lastMessageSenderId': senderId,
      'carPlateNumber': carPlateNumber,
      'carBrand': carBrand,
    }, SetOptions(merge: true));

    // Send notification to receiver
    try {
      // Get sender's name for notification
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['nickname'] ??
          senderDoc.data()?['displayName'] ??
          'Utilizator';

      await NotificationService.sendMessageNotification(
        receiverId: receiverId,
        senderName: senderName,
        message: message,
        conversationId: conversationId,
        carBrand: carBrand,
      );
    } catch (e) {
      print('❌ Error sending message notification: $e');
    }
  }

  // Get messages for a conversation
  static Stream<List<ChatMessage>> getMessages(
      String senderId, String receiverId) {
    final conversationId = _getConversationId(senderId, receiverId);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson(doc.id, doc.data()))
            .toList());
  }

  // Get user's conversations with online status and user info
  static Stream<List<Map<String, dynamic>>> getUserConversations(
      String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final otherUserId =
            participants.firstWhere((id) => id != userId, orElse: () => '');

        // Get other user's online status, last seen, and profile info
        bool isOnline = false;
        DateTime? lastSeen;
        String? otherUserNickname;
        String? otherUserDisplayName;

        if (otherUserId.isNotEmpty) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(otherUserId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final userIsOnline = userData['isOnline'] ?? false;
              final userLastSeen =
                  (userData['lastSeen'] as Timestamp?)?.toDate();

              if (userIsOnline && userLastSeen != null) {
                final difference = DateTime.now().difference(userLastSeen);
                isOnline = difference.inMinutes < 5;
              }
              lastSeen = userLastSeen;

              // Get user's nickname or fallback to display name
              otherUserNickname = userData['nickname'] as String?;
              otherUserDisplayName = userData['displayName'] as String?;
            }
          } catch (e) {
            print('Error getting user status: $e');
          }
        }

        conversations.add({
          'id': doc.id,
          ...data,
          'otherUserId': otherUserId,
          'otherUserNickname': otherUserNickname,
          'otherUserDisplayName': otherUserDisplayName,
          'isOnline': isOnline,
          'otherUserLastSeen':
              lastSeen != null ? Timestamp.fromDate(lastSeen) : null,
        });
      }

      return conversations;
    });
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
      String senderId, String receiverId) async {
    final conversationId = _getConversationId(senderId, receiverId);

    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Get conversation ID between two users
  static String _getConversationId(String userId1, String userId2) {
    final List<String> userIds = [userId1, userId2];
    userIds.sort();
    return userIds.join('_');
  }

  // Get quick messages in English
  static List<String> getQuickMessages() {
    return [
      'The car is blocked.',
      'I have issues with this car.',
      'I will evacuate the car.',
      'Thank you for the information.',
      'I am interested in this car.',
      'Please call me.',
    ];
  }

  // Get unread message count for a specific conversation
  static Stream<int> getUnreadMessageCount(String senderId, String receiverId) {
    final conversationId = _getConversationId(senderId, receiverId);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('receiverId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total unread message count for a user across all conversations
  static Stream<int> getTotalUnreadMessageCount(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((conversationSnapshot) async {
      int totalUnread = 0;

      for (final conversationDoc in conversationSnapshot.docs) {
        final unreadMessages = await _firestore
            .collection('conversations')
            .doc(conversationDoc.id)
            .collection('messages')
            .where('receiverId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

        totalUnread += unreadMessages.docs.length;
      }

      return totalUnread;
    });
  }

  // Clear chat messages between two users
  static Future<void> clearChat(String senderId, String receiverId) async {
    final conversationId = _getConversationId(senderId, receiverId);

    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final messages = await messagesRef.get();
    final batch = _firestore.batch();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Update conversation metadata to clear last message
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': '',
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete entire conversation
  static Future<void> deleteConversation(
      String senderId, String receiverId) async {
    final conversationId = _getConversationId(senderId, receiverId);

    // First delete all messages
    final messagesRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages');

    final messages = await messagesRef.get();
    final batch = _firestore.batch();

    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the conversation document
    batch.delete(_firestore.collection('conversations').doc(conversationId));

    await batch.commit();
  }

  // Report a user
  static Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'status': 'pending',
    });
  }

  // Block a user
  static Future<void> blockUser(String userId, String blockedUserId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('blocked_users')
        .doc(blockedUserId)
        .set({
      'blockedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Check if current user is blocked by another user
  static Future<bool> isUserBlocked(
      String currentUserId, String otherUserId) async {
    try {
      // Check if otherUser has blocked currentUser
      final doc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('blocked_users')
          .doc(currentUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false; // If we can't check, assume not blocked to allow messaging
    }
  }

  // Unblock a user
  static Future<void> unblockUser(String userId, String blockedUserId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('blocked_users')
        .doc(blockedUserId)
        .delete();
  }

  // Edit a message
  static Future<void> editMessage(String messageId, String newMessage) async {
    // Find the message in conversations
    final conversationsQuery =
        await _firestore.collection('conversations').get();

    for (final conversationDoc in conversationsQuery.docs) {
      final messageDoc = await conversationDoc.reference
          .collection('messages')
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        await messageDoc.reference.update({
          'message': newMessage,
          'isEdited': true,
          'editedAt': Timestamp.fromDate(DateTime.now()),
        });
        break;
      }
    }
  }

  // Delete a message
  static Future<void> deleteMessage(String messageId) async {
    // Find the message in conversations
    final conversationsQuery =
        await _firestore.collection('conversations').get();

    for (final conversationDoc in conversationsQuery.docs) {
      final messageDoc = await conversationDoc.reference
          .collection('messages')
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        await messageDoc.reference.delete();
        break;
      }
    }
  }

  // Send reply message
  static Future<void> sendReplyMessage({
    required String senderId,
    required String receiverId,
    required String message,
    required String replyToId,
    required String replyToMessage,
    String? carPlateNumber,
    String? carBrand,
  }) async {
    final chatMessage = ChatMessage(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: DateTime.now(),
      carPlateNumber: carPlateNumber,
      carBrand: carBrand,
      replyToId: replyToId,
      replyToMessage: replyToMessage,
    );

    // Create or get conversation ID
    final conversationId = _getConversationId(senderId, receiverId);

    // Add message to messages subcollection
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(chatMessage.toJson());

    // Update conversation metadata
    await _firestore.collection('conversations').doc(conversationId).set({
      'participants': [senderId, receiverId],
      'lastMessage': message,
      'lastMessageTime': Timestamp.fromDate(DateTime.now()),
      'lastMessageSenderId': senderId,
      'carPlateNumber': carPlateNumber,
      'carBrand': carBrand,
    }, SetOptions(merge: true));
  }
}
