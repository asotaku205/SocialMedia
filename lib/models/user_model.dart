import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String userName;
  final String photoURL;
  final String bio;
  final int followers;
  final int following;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final List<String> interests;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.userName,
    this.photoURL = '',
    this.bio = '',
    this.followers = 0,
    this.following = 0,
    this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.interests = const [],
  });

  // Chuyển từ Firebase Document sang UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      userName: map['userName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      bio: map['bio'] ?? '',
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      isVerified: map['isVerified'] ?? false,
      interests: List<String>.from(map['interests'] ?? []),
    );
  }

  // Chuyển từ UserModel sang Map để lưu vào Firebase
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'userName': userName,
      'photoURL': photoURL,
      'bio': bio,
      'followers': followers,
      'following': following,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isVerified': isVerified,
      'interests': interests,
    };
  }
}