import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  //get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  static Future<void> sendMessage(
    String chatId,
    String receiverId,
    String content,
    String messageType,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      final chatId = _createChatId(currentUser.uid, receiverId);
      final messageDoc = _firestore.collection('messages').doc();

      print('📤 Sending message to $receiverId...');

      // Lấy session key và mã hóa tin nhắn
      final sessionKey = await EncryptionService.getOrCreateSessionKey(
        chatId,
        receiverId,
      );
      print('🔐 Encrypting message content...');
      final encryptedData = EncryptionService.encryptMessage(
        content,
        sessionKey,
      );

      // Tạo fingerprint
      final timestamp = DateTime.now();
      final fingerprint = EncryptionService.generateFingerprint(
        content,
        timestamp.toIso8601String(),
      );

      final message = MessageModel(
        id: messageDoc.id,
        chatId: chatId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        encryptedContent: encryptedData['encryptedContent']!,
        iv: encryptedData['iv']!,
        hmac: encryptedData['hmac']!,
        content: '', // Không lưu plaintext lên server
        messageType: messageType,
        timestamp: timestamp,
        isRead: false,
        isDeleted: false,
        fingerprint: fingerprint,
      );

      print('💾 Saving encrypted message to Firestore...');
      await messageDoc.set(message.toMap());
      print('✅ Message sent successfully!');
    } catch (e) {
      print('❌ Failed to send message: $e');

      // Cung cấp thông báo lỗi chi tiết hơn
      if (e.toString().contains('Recipient has not set up encryption keys')) {
        throw Exception(
          'Cannot send message: Recipient needs to open the app to set up encryption first.',
        );
      } else if (e.toString().contains('Your encryption keys are missing')) {
        throw Exception(
          'Cannot send message: Please restore your encryption key from Settings > Backup Private Key',
        );
      } else {
        throw Exception('Failed to send message: $e');
      }
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
        .asyncMap((snapshot) async {
          List<MessageModel> messages = [];

          try {
            // Lấy session key - có thể throw exception nếu không có private key
            final sessionKey = await EncryptionService.getOrCreateSessionKey(
              chatId,
              otherUserId,
            );

            for (var doc in snapshot.docs) {
              final messageData = doc.data();
              var message = MessageModel.fromMap(messageData, doc.id);

              // Giải mã tin nhắn nếu có mã hóa
              if (message.encryptedContent.isNotEmpty &&
                  message.iv != null &&
                  message.hmac != null) {
                try {
                  final decryptedContent = EncryptionService.decryptMessage(
                    message.encryptedContent,
                    message.iv!,
                    message.hmac!,
                    sessionKey,
                  );
                  message = message.copyWith(content: decryptedContent);
                } catch (e) {
                  print('Error decrypting message ${message.id}: $e');
                  // Hiển thị thông báo lỗi khác nhau tùy loại lỗi
                  if (e.toString().contains('Private key not found') ||
                      e.toString().contains('encryption keys are missing')) {
                    message = message.copyWith(
                      content:
                          '🔒 [Message Encrypted - Keys Missing. Restore from Settings > Security > Backup Private Key]',
                    );
                  } else if (e.toString().contains('HMAC')) {
                    message = message.copyWith(
                      content: '🔒 [Message Corrupted - Cannot Decrypt]',
                    );
                  } else {
                    message = message.copyWith(
                      content: '🔒 [Encrypted Message]',
                    );
                  }
                }
              }
              messages.add(message);
            }
          } catch (e) {
            print('❌ Error getting session key: $e');

            // Nếu không lấy được session key, vẫn hiển thị messages nhưng không giải mã được
            for (var doc in snapshot.docs) {
              final messageData = doc.data();
              var message = MessageModel.fromMap(messageData, doc.id);

              if (message.encryptedContent.isNotEmpty) {
                // Hiển thị thông báo lỗi cụ thể hơn
                if (e.toString().contains('Private key not found') ||
                    e.toString().contains('encryption key is missing')) {
                  message = message.copyWith(
                    content:
                        '[🔒 Encrypted - Please restore your encryption key from Settings]',
                  );
                } else {
                  message = message.copyWith(content: '[🔒 Encrypted Message]');
                }
              }

              messages.add(message);
            }
          }

          return messages;
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

      return MessageModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
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
