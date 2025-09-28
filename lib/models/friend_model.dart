import 'package:cloud_firestore/cloud_firestore.dart';
class friendShipModel {
  final String uid;
  final String senderId;
  final String receiverId;
  final String status; // pending, accepted, blocked
  final DateTime? createdAt;
  final DateTime? updatedAt;

  friendShipModel({
    required this.uid,
    required this.senderId,
    required this.receiverId,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  // Chuyển từ Firebase Document sang UserModel
  factory friendShipModel.fromMap(Map<String, dynamic> map, String documentId) {
    return friendShipModel(
      uid: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  // Chuyển từ UserModel sang Map để lưu vào Firebase
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}