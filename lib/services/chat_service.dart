import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class ChatService{
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  //get user stream
   Stream<List<Map<String,dynamic>>> getUserStream(){
     return _firestore.collection('users').snapshots().map((snapshot) =>
         snapshot.docs.map((doc) => doc.data() as Map<String,dynamic>).toList());
   }

   static Future<void> sendMessage(String chatId, String receiverId, String content, String messageType) async {
     final currentUser = _auth.currentUser;

     if (currentUser == null) {
       throw Exception('User not logged in');
     }

     try {
       final chatId = _createChatId(currentUser.uid, receiverId);
       final messageDoc = _firestore.collection('messages').doc();

       final message = MessageModel(
         id: messageDoc.id,
         chatId: chatId,
         senderId: currentUser.uid,
         receiverId: receiverId,
         content: content,
         messageType: messageType,
         timestamp: DateTime.now(),
         isRead: false,
         isDeleted: false,
       );

       await messageDoc.set(message.toMap());
     } catch (e) {
       throw Exception('Failed to send message: $e');
     }
   }
   static Stream<List<MessageModel>> getMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final chatId = _createChatId(currentUser.uid, otherUserId);

    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get latest message for a specific chat
  static Future<MessageModel?> getLatestMessage(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    final chatId = _createChatId(currentUser.uid, otherUserId);

    try {
      final querySnapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return MessageModel.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
    } catch (e) {
      print('Error getting latest message: $e');
      return null;
    }
  }

  // Create a unique chat ID based on user IDs
  static String _createChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return users.join('_');
  }
}