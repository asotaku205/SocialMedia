import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String userName;
  final String photoURL;
  final String bio;
  final int friendCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isVerified;
  final List<String> friends;
  final List<String> interests;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.userName,
    this.photoURL = '',
    this.bio = '',
    this.friendCount = 0,
    this.createdAt,
    this.updatedAt,
    this.isVerified = false,
    this.interests = const [],
    this.friends = const [],
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
      friendCount: map['friendCount'] ?? 0, // Sửa đúng kiểu int
      createdAt: map['createdAt'] is Timestamp ? map['createdAt'].toDate() : null,
      updatedAt: map['updatedAt'] is Timestamp ? map['updatedAt'].toDate() : null,
      isVerified: map['isVerified'] ?? false,
      interests: List<String>.from(map['interests'] ?? []),
      friends: List<String>.from(map['friends'] ?? []),
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
      'friendCount': friendCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isVerified': isVerified,
      'interests': interests,
      'friends': friends,
    };
  }

  // Copy method để tạo instance mới với các giá trị cập nhật
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? userName,
    String? photoURL,
    String? bio,
    int? friendCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    List<String>? interests,
    List<String>? friends,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      userName: userName ?? this.userName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      friendCount: friendCount ?? this.friendCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      interests: interests ?? this.interests,
      friends: friends ?? this.friends,
    );
  }
}