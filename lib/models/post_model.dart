// File: post_model.dart
// Đây là model cho bài đăng (Post) trong ứng dụng Flutter kết nối với Firebase Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

/// Class PostModel đại diện cho một bài đăng
class PostModel {
  // ID của bài đăng (trùng với documentId trên Firestore)
  final String id;

  // UID người đăng
  final String authorId;

  // Tên người đăng
  final String authorName;

  // Ảnh đại diện người đăng, có thể để trống
  final String authorAvatar;

  // Nội dung text của bài đăng
  final String content;

  // Danh sách URL hình ảnh kèm theo bài đăng
  final List<String> imageUrls;

  // Số lượt thích
  final int likes;

  // Số lượt bình luận
  final int comments;

  // Thời gian tạo bài đăng
  final DateTime createdAt;

  // Thời gian cập nhật bài đăng
  final DateTime updatedAt;

  // Danh sách hashtag
  final List<String> hashtags;

  // Vị trí bài đăng
  final String location;

  // Danh sách UID những người đã like bài đăng
  final List<String> likedBy;

  /// Constructor của PostModel
  /// Một số trường có giá trị mặc định nếu không truyền vào
  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar = '',
    required this.content,
    this.imageUrls = const [],
    this.likes = 0,
    this.comments = 0,
    required this.createdAt,
    required this.updatedAt,
    this.hashtags = const [],
    this.location = '',
    this.likedBy = const [],
  });

  /// Factory constructor để tạo PostModel từ dữ liệu Firestore
  /// [map] là dữ liệu lấy từ document snapshot
  /// [documentId] là ID của document trong Firestore
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      authorId: map['authorId'] ?? '', // Nếu null sẽ để rỗng
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(
        map['imageUrls'] ?? [],
      ), // Convert list dynamic -> List<String>
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp)
          .toDate(), // Timestamp -> DateTime
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      location: map['location'] ?? '',
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  /// Chuyển PostModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt), // DateTime -> Timestamp
      'updatedAt': FieldValue.serverTimestamp(), // Thời gian cập nhật tự động
      'hashtags': hashtags,
      'location': location,
      'likedBy': likedBy,
    };
  }
}
