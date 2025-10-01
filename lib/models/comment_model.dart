// File: lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorId;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  // Convert từ Firestore Document sang CommentModel
  factory CommentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CommentModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert từ CommentModel sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
