import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  // final String encryptedContent;
  // final String hmac;
  final String content;
  final String messageType; // text, image, file, audio
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;
  // final DateTime? deleteAt;
  final String? fingerprint;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    // required this.encryptedContent,
    // required this.hmac,
    this.content = '',
    required this.messageType,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    // this.deleteAt,
    this.fingerprint,
    this.metadata,
  });
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      // 'encryptedContent': encryptedContent,
      // 'hmac': hmac,
      'content': content,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDeleted': isDeleted,
      // 'deleteAt': deleteAt != null ? Timestamp.fromDate(deleteAt!) : null,
      'fingerprint': fingerprint,
      'metadata': metadata,
    };
  }
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      // encryptedContent: map['encryptedContent'] ?? '',
      // hmac: map['hmac'] ?? '',
      content: map['content'] ?? '',
      messageType: map['messageType'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      // deleteAt: map['deleteAt'] != null
      //     ? (map['deleteAt'] as Timestamp).toDate()
      //     : null,
      fingerprint: map['fingerprint'],
      metadata: map['metadata'],
    );
  } MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? encryptedContent,
    String? hmac,
    String? content,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    bool? isDeleted,
    DateTime? deleteAt,
    String? fingerprint,
    Map<String, dynamic>? metadata,
  })
  {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      // encryptedContent: encryptedContent ?? this.encryptedContent,
      // hmac: hmac ?? this.hmac,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      // deleteAt: deleteAt ?? this.deleteAt,
      fingerprint: fingerprint ?? this.fingerprint,
      metadata: metadata ?? this.metadata,
    );
  }
}
// Model cho Chat metadata
class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final int autoDeleteMinutes;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    required this.unreadCount,
    required this.createdAt,
    this.autoDeleteMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'autoDeleteMinutes': autoDeleteMinutes,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastSenderId: map['lastSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      autoDeleteMinutes: map['autoDeleteMinutes'] ?? 0,
    );
  }
}