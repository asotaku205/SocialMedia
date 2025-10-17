import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _storage = FirebaseStorage.instance;

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

      // Lấy session key và mã hóa tin nhắn
      final sessionKey = await EncryptionService.getOrCreateSessionKey(
        chatId,
        receiverId,
      );
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

      await messageDoc.set(message.toMap());
    } catch (e) {
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
                          ' [Message Encrypted - Keys Missing. Restore from Settings > Security > Backup Private Key]',
                    );
                  } else if (e.toString().contains('HMAC')) {
                    message = message.copyWith(
                      content: ' [Message Corrupted - Cannot Decrypt]',
                    );
                  } else {
                    message = message.copyWith(
                      content: ' [Encrypted Message]',
                    );
                  }
                }
              }
              messages.add(message);
            }
          } catch (e) {
            print('Error getting session key: $e');

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
                        '[ Encrypted - Please restore your encryption key from Settings]',
                  );
                } else {
                  message = message.copyWith(content: '[ Encrypted Message]');
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

  // --- IMAGE MESSAGE METHODS ---
  /// Upload ảnh cho tin nhắn chat
  static Future<String?> _uploadChatImage(XFile imageFile) async {
    try {
      // Trên web, sử dụng base64 fallback
      if (kIsWeb) {
        print('Using base64 fallback for web chat image upload');

        final Uint8List imageBytes = await imageFile.readAsBytes();

        // Giới hạn kích thước
        if (imageBytes.length > 2 * 1024 * 1024) {
          // 2MB cho chat images
          throw Exception(
            'Ảnh quá lớn cho web upload. Vui lòng chọn ảnh nhỏ hơn 2MB',
          );
        }

        final String base64String = base64Encode(imageBytes);
        final String dataUrl = 'data:image/jpeg;base64,$base64String';

        print('Base64 chat image upload completed');
        return dataUrl;
      }

      // Mobile approach - Firebase Storage
      String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('chat_images/$fileName');

      // Đọc file thành bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Upload
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Lỗi upload ảnh chat: $e');
      return null;
    }
  }

  /// Gửi tin nhắn với ảnh đính kèm (có mã hóa)
  static Future<void> sendMessageWithImage(
    String receiverId,
    XFile imageFile,
    String caption,
  ) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      // Upload ảnh trước
      String? imageUrl = await _uploadChatImage(imageFile);
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      final chatId = _createChatId(currentUser.uid, receiverId);
      final messageDoc = _firestore.collection('messages').doc();

      // Lấy session key
      final sessionKey = await EncryptionService.getOrCreateSessionKey(
        chatId,
        receiverId,
      );

      // Mã hóa caption (nếu có)
      String encryptedCaption = '';
      String? captionIv;
      String? captionHmac;

      if (caption.isNotEmpty) {
        final encryptedData = EncryptionService.encryptMessage(
          caption,
          sessionKey,
        );
        encryptedCaption = encryptedData['encryptedContent']!;
        captionIv = encryptedData['iv']!;
        captionHmac = encryptedData['hmac']!;
      }

      // Tạo fingerprint
      final timestamp = DateTime.now();
      final fingerprint = EncryptionService.generateFingerprint(
        imageUrl + caption,
        timestamp.toIso8601String(),
      );

      // Tạo message với metadata chứa thông tin ảnh
      final message = MessageModel(
        id: messageDoc.id,
        chatId: chatId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        encryptedContent: encryptedCaption,
        iv: captionIv,
        hmac: captionHmac,
        content: '', // Không lưu plaintext
        messageType: 'image',
        timestamp: timestamp,
        isRead: false,
        isDeleted: false,
        fingerprint: fingerprint,
        metadata: {
          'imageUrl': imageUrl,
          'caption': caption.isEmpty ? null : caption,
        },
      );

      await messageDoc.set(message.toMap());
    } catch (e) {
      if (e.toString().contains('Recipient has not set up encryption keys')) {
        throw Exception(
          'Cannot send message: Recipient needs to open the app to set up encryption first.',
        );
      } else if (e.toString().contains('Your encryption keys are missing')) {
        throw Exception(
          'Cannot send message: Please restore your encryption key from Settings > Backup Private Key',
        );
      } else {
        throw Exception('Failed to send image message: $e');
      }
    }
  }

  // Đếm số cuộc hội thoại có tin nhắn chưa đọc (không phải tổng số tin nhắn)
  static Stream<int> getUnreadMessagesCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          // Đếm số người gửi khác nhau (số cuộc hội thoại có tin nhắn mới)
          Set<String> senderIds = {};
          for (var doc in snapshot.docs) {
            final senderId = doc.data()['senderId'] as String?;
            if (senderId != null) {
              senderIds.add(senderId);
            }
          }
          return senderIds.length;
        });
  }

  // Đánh dấu tất cả tin nhắn từ một người dùng là đã đọc
  static Future<void> markMessagesAsRead(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final chatId = _createChatId(currentUser.uid, otherUserId);

      // Lấy tất cả tin nhắn chưa đọc từ người dùng khác trong chat này
      final snapshot = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      // Sử dụng batch để update nhiều document cùng lúc
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}
