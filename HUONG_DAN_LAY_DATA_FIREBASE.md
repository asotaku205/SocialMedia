# HƯỚNG DẪN LẤY DATA TỪ FIREBASE ĐỂ HIỂN THỊ LÊN APP

## MỤC LỤC
1. [Kiến thức cơ bản về Firestore](#1-kiến-thức-cơ-bản-về-firestore)
2. [Cấu trúc dữ liệu Firebase](#2-cấu-trúc-dữ-liệu-firebase)
3. [Lấy Profile User](#3-lấy-profile-user)
4. [Lấy danh sách Posts](#4-lấy-danh-sách-posts)
5. [Real-time Updates với Stream](#5-real-time-updates-với-stream)
6. [Pagination và Performance](#6-pagination-và-performance)
7. [Error Handling](#7-error-handling)
8. [Cache và Offline Support](#8-cache-và-offline-support)
9. [**VÍ DỤ ÁP DỤNG VÀO PROJECT**](#9-ví-dụ-áp-dụng-vào-project)
10. [**HƯỚNG DẪN THỰC HIỆN TỪNG BƯỚC**](#10-hướng-dẫn-thực-hiện-từng-bước)
11. [Best Practices](#11-best-practices)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. KIẾN THỨC CƠ BẢN VỀ FIRESTORE

### 1.1 Firestore là gì?
```
Firestore = NoSQL Database từ Firebase
- Lưu trữ dữ liệu dạng Documents và Collections
- Real-time synchronization
- Offline support tự động
- Scalable và secure
```

### 1.2 Cấu trúc Firestore
```
Database
├── Collection (users)
│   ├── Document (user1_uid)
│   │   ├── Field: email
│   │   ├── Field: displayName
│   │   └── Field: photoURL
│   └── Document (user2_uid)
└── Collection (posts)
    ├── Document (post1_id)
    └── Document (post2_id)
```

### 1.3 Các phương thức quan trọng
```dart
// Lấy 1 document
FirebaseFirestore.instance.collection('users').doc('uid').get()

// Lấy nhiều documents
FirebaseFirestore.instance.collection('posts').get()

// Lắng nghe thay đổi real-time
FirebaseFirestore.instance.collection('users').doc('uid').snapshots()

// Query với điều kiện
FirebaseFirestore.instance.collection('posts')
  .where('authorId', isEqualTo: 'uid')
  .orderBy('createdAt', descending: true)
  .limit(10)
  .get()
```

---

## 2. CẤU TRÚC DỮ LIỆU FIREBASE

### 2.1 Collection "users"
```json
{
  "users": {
    "user_uid_123": {
      "email": "user@gmail.com",
      "displayName": "John Doe",
      "userName": "john_doe",
      "photoURL": "https://...",
      "bio": "Flutter Developer",
      "followers": 150,
      "following": 80,
      "createdAt": "2024-01-15T10:30:00Z",
      "updatedAt": "2024-01-20T15:45:00Z",
      "isVerified": true,
      "interests": ["flutter", "firebase", "mobile"]
    }
  }
}
```

### 2.2 Collection "posts" (cần tạo model)
```json
{
  "posts": {
    "post_id_123": {
      "authorId": "user_uid_123",
      "authorName": "John Doe",
      "authorAvatar": "https://...",
      "content": "Hôm nay học Flutter...",
      "imageUrls": ["https://image1.jpg", "https://image2.jpg"],
      "likes": 25,
      "comments": 5,
      "createdAt": "2024-01-20T14:30:00Z",
      "updatedAt": "2024-01-20T14:30:00Z",
      "hashtags": ["flutter", "coding"],
      "location": "Hà Nội, Việt Nam"
    }
  }
}
```

---

## 3. LẤY PROFILE USER

### 3.1 Tạo Service để lấy User Data

```dart
// File: lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// LẤY PROFILE USER HIỆN TẠI (1 LẦN)
  /// Sử dụng khi cần lấy data user để hiển thị profile
  static Future<UserModel?> getCurrentUserProfile(String uid) async {
    try {
      // Lấy document user từ Firestore bằng UID
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      // Kiểm tra document có tồn tại không
      if (doc.exists && doc.data() != null) {
        // Convert Firestore data sang UserModel
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  /// LẤY PROFILE USER REAL-TIME (STREAM)
  /// Sử dụng khi cần update real-time khi user thay đổi profile
  static Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    });
  }
  
  /// LẤY PROFILE USER KHÁC (PUBLIC PROFILE)
  /// Sử dụng khi xem profile user khác
  static Future<UserModel?> getUserProfileById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
  
  /// TÌM KIẾM USER THEO USERNAME
  /// Sử dụng cho tính năng search user
  static Future<List<UserModel>> searchUsersByUsername(String query) async {
    try {
      // Query users có userName chứa query string
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('userName', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();
      
      // Convert tất cả documents sang UserModel
      return snapshot.docs
          .map((doc) => UserModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
```

### 3.2 Sử dụng trong UI Widget

```dart
// File: lib/features/profile/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import '../../../services/user_service.dart';
import '../../../models/user_model.dart';

class UserProfileCard extends StatefulWidget {
  final String userId;
  
  const UserProfileCard({super.key, required this.userId});
  
  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  UserModel? user;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  /// Load user profile từ Firebase
  Future<void> _loadUserProfile() async {
    try {
      UserModel? loadedUser = await UserService.getCurrentUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          user = loadedUser;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e'))
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Hiển thị loading khi đang tải data
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Hiển thị error nếu không load được user
    if (user == null) {
      return const Center(
        child: Text('Unable to load user profile'),
      );
    }
    
    // Hiển thị profile user
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundImage: user!.photoURL.isNotEmpty 
                  ? NetworkImage(user!.photoURL)
                  : null,
              child: user!.photoURL.isEmpty 
                  ? Text(
                      user!.displayName.isNotEmpty 
                          ? user!.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Display Name
            Text(
              user!.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // Username
            Text(
              '@${user!.userName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            
            // Bio
            if (user!.bio.isNotEmpty)
              Text(
                user!.bio,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            
            // Followers & Following
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Followers', user!.followers),
                _buildStatItem('Following', user!.following),
                _buildStatItem('Posts', 0), // Sẽ implement sau
              ],
            ),
            
            // Verified Badge
            if (user!.isVerified)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Widget hiển thị số liệu thống kê
  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
```

### 3.3 Sử dụng Stream cho Real-time Updates

```dart
// File: lib/features/profile/screens/profile_screen.dart
class ProfileScreen extends StatelessWidget {
  final String userId;
  
  const ProfileScreen({super.key, required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<UserModel?>(
        // Stream tự động update khi user data thay đổi
        stream: UserService.getUserProfileStream(userId),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}')
            );
          }
          
          // No data state
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('User not found')
            );
          }
          
          UserModel user = snapshot.data!;
          
          // Success state - hiển thị profile
          return SingleChildScrollView(
            child: Column(
              children: [
                UserProfileCard(userId: userId),
                // Thêm các widget khác như posts list...
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## 4. LẤY DANH SÁCH POSTS

### 4.1 Tạo Post Model

```dart
// File: lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> imageUrls;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> hashtags;
  final String location;
  final List<String> likedBy; // UIDs của users đã like
  
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
  
  // Convert từ Firestore Document sang PostModel
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      location: map['location'] ?? '',
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }
  
  // Convert từ PostModel sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'hashtags': hashtags,
      'location': location,
      'likedBy': likedBy,
    };
  }
}
```

### 4.2 Tạo Post Service

```dart
// File: lib/services/post_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// LẤY DANH SÁCH POSTS CHO FEED (TẤT CẢ POSTS)
  /// Sắp xếp theo thời gian tạo mới nhất
  static Future<List<PostModel>> getFeedPosts({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true) // Mới nhất trước
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error getting feed posts: $e');
      return [];
    }
  }
  
  /// LẤY POSTS CỦA MỘT USER CỤ THỂ
  /// Sử dụng cho profile screen
  static Future<List<PostModel>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }
  
  /// LẤY 1 POST CỤ THỂ
  /// Sử dụng khi cần hiển thị chi tiết post
  static Future<PostModel?> getPostById(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return PostModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }
  
  /// LẤY POSTS THEO HASHTAG
  /// Sử dụng cho tính năng tìm kiếm hashtag
  static Future<List<PostModel>> getPostsByHashtag(String hashtag, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('hashtags', arrayContains: hashtag.toLowerCase())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error getting posts by hashtag: $e');
      return [];
    }
  }
  
  /// STREAM CHO REAL-TIME POSTS
  /// Tự động cập nhật khi có post mới
  static Stream<List<PostModel>> getFeedPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    });
  }
  
  /// PAGINATION - LẤY POSTS TIẾP THEO
  /// Sử dụng cho infinite scrolling
  static Future<List<PostModel>> getNextPosts({
    required DocumentSnapshot lastDocument,
    int limit = 20,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDocument) // Tiếp tục từ document cuối
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error getting next posts: $e');
      return [];
    }
  }
}
```

### 4.3 Sử dụng trong UI Widget

```dart
// File: lib/features/feed/widgets/post_list.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});
  
  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  List<PostModel> posts = [];
  bool isLoading = true;
  bool hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }
  
  /// Load posts từ Firebase
  Future<void> _loadPosts() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      List<PostModel> feedPosts = await PostService.getFeedPosts();
      
      if (mounted) {
        setState(() {
          posts = feedPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Error state
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Unable to load posts'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Empty state
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts available'),
            SizedBox(height: 8),
            Text('Be the first to share something!', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Success state - hiển thị danh sách posts
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }
}
```

### 4.4 Widget hiển thị Post Card

```dart
// File: lib/features/feed/widgets/post_card.dart
import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final PostModel post;
  
  const PostCard({super.key, required this.post});
  
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likesCount;
  bool isLiking = false;
  
  @override
  void initState() {
    super.initState();
    String? currentUserId = AuthService.currentUser?.uid;
    isLiked = currentUserId != null && widget.post.likedBy.contains(currentUserId);
    likesCount = widget.post.likes;
  }
  
  Future<void> _toggleLike() async {
    if (isLiking) return;
    
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return;
    
    setState(() => isLiking = true);
    
    // Optimistic update
    setState(() {
      if (isLiked) {
        likesCount--;
        isLiked = false;
      } else {
        likesCount++;
        isLiked = true;
      }
    });
    
    String result = await PostService.toggleLike(widget.post.id, currentUserId);
    
    if (result != 'success') {
      // Revert on error
      setState(() {
        if (isLiked) {
          likesCount--;
          isLiked = false;
        } else {
          likesCount++;
          isLiked = true;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    }
    
    setState(() => isLiking = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.authorAvatar.isNotEmpty 
                  ? NetworkImage(widget.post.authorAvatar)
                  : null,
              child: widget.post.authorAvatar.isEmpty 
                  ? Text(widget.post.authorName.isNotEmpty 
                      ? widget.post.authorName[0].toUpperCase() 
                      : 'U')
                  : null,
            ),
            title: Text(
              widget.post.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(timeago.format(widget.post.createdAt)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show post options
              },
            ),
          ),
          
          // Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          
          // Images
          if (widget.post.imageUrls.isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: PageView.builder(
                itemCount: widget.post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.post.imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Location
          if (widget.post.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.post.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          // Hashtags
          if (widget.post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.post.hashtags.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to hashtag posts
                    },
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likesCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Navigate to comments
                  },
                ),
                Text('${widget.post.comments}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Handle share
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. REAL-TIME UPDATES VỚI STREAM

### 5.1 Sử dụng StreamBuilder cho Posts

```dart
// File: lib/features/feed/screens/feed_screen.dart
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
      ),
      body: StreamBuilder<List<PostModel>>(
        // Stream tự động update khi có post mới
        stream: PostService.getFeedPostsStream(limit: 50),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available'));
          }
          
          List<PostModel> posts = snapshot.data!;
          
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create post screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 5.2 Combine User và Posts Stream

```dart
// File: lib/features/profile/screens/user_profile_screen.dart
class UserProfileScreen extends StatelessWidget {
  final String userId;
  
  const UserProfileScreen({super.key, required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          // User Profile Section - Real-time
          StreamBuilder<UserModel?>(
            stream: UserService.getUserProfileStream(userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!userSnapshot.hasData) {
                return const Center(child: Text('User not found'));
              }
              
              return UserProfileCard(userId: userId);
            },
          ),
          
          // User Posts Section - Real-time
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: PostService.getUserPostsStream(userId),
              builder: (context, postsSnapshot) {
                if (postsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }
                
                List<PostModel> posts = postsSnapshot.data!;
                
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return PostCard(post: posts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. PAGINATION VÀ PERFORMANCE

### 6.1 Infinite Scrolling Implementation

```dart
// File: lib/features/feed/widgets/infinite_post_list.dart
class InfinitePostList extends StatefulWidget {
  const InfinitePostList({super.key});
  
  @override
  State<InfinitePostList> createState() => _InfinitePostListState();
}

class _InfinitePostListState extends State<InfinitePostList> {
  final ScrollController _scrollController = ScrollController();
  List<PostModel> posts = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDocument;
  
  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Load batch đầu tiên của posts
  Future<void> _loadInitialPosts() async {
    setState(() => isLoading = true);
    
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        posts = snapshot.docs
            .map((doc) => PostModel.fromMap(
                doc.data() as Map<String, dynamic>, 
                doc.id
              ))
            .toList();
        lastDocument = snapshot.docs.last;
      }
    } catch (e) {
      print('Error loading initial posts: $e');
    }
    
    setState(() => isLoading = false);
  }
  
  /// Load thêm posts khi scroll tới cuối
  Future<void> _loadMorePosts() async {
    if (isLoading || !hasMore || lastDocument == null) return;
    
    setState(() => isLoading = true);
    
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastDocument!)
          .limit(20)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        List<PostModel> newPosts = snapshot.docs
            .map((doc) => PostModel.fromMap(
                doc.data() as Map<String, dynamic>, 
                doc.id
              ))
            .toList();
        
        posts.addAll(newPosts);
        lastDocument = snapshot.docs.last;
        
        // Nếu trả về ít hơn limit, nghĩa là đã hết data
        if (snapshot.docs.length < 20) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      print('Error loading more posts: $e');
    }
    
    setState(() => isLoading = false);
  }
  
  /// Listen scroll events
  void _onScroll() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: posts.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Hiển thị posts
        if (index < posts.length) {
          return PostCard(post: posts[index]);
        }
        
        // Hiển thị loading indicator ở cuối list
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
```

### 6.2 Caching và Performance Tips

```dart
// File: lib/services/cache_service.dart
class CacheService {
  static final Map<String, UserModel> _userCache = {};
  static final Map<String, List<PostModel>> _postCache = {};
  
  /// Cache user data để tránh query Firebase nhiều lần
  static UserModel? getCachedUser(String uid) {
    return _userCache[uid];
  }
  
  static void cacheUser(UserModel user) {
    _userCache[user.uid] = user;
  }
  
  /// Cache posts với time-based expiry
  static List<PostModel>? getCachedPosts(String key) {
    return _postCache[key];
  }
  
  static void cachePosts(String key, List<PostModel> posts) {
    _postCache[key] = posts;
  }
  
  /// Clear cache khi cần
  static void clearCache() {
    _userCache.clear();
    _postCache.clear();
  }
}

// Sử dụng cache trong UserService
class UserService {
  static Future<UserModel?> getUserWithCache(String uid) async {
    // Kiểm tra cache trước
    UserModel? cachedUser = CacheService.getCachedUser(uid);
    if (cachedUser != null) {
      return cachedUser;
    }
    
    // Nếu không có trong cache, query Firebase
    UserModel? user = await getCurrentUserProfile(uid);
    if (user != null) {
      CacheService.cacheUser(user);
    }
    
    return user;
  }
}
```

---

## 7. ERROR HANDLING

### 7.1 Custom Error Classes

```dart
// File: lib/core/errors/firebase_exceptions.dart
class FirebaseException implements Exception {
  final String message;
  final String? code;
  
  FirebaseException(this.message, {this.code});
  
  @override
  String toString() => 'FirebaseException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}
```

### 7.2 Robust Error Handling

```dart
// File: lib/services/robust_post_service.dart
class RobustPostService {
  static Future<List<PostModel>> getFeedPostsWithErrorHandling({
    int limit = 20,
    bool useCache = true,
  }) async {
    try {
      // Thử lấy từ cache trước (nếu offline)
      if (useCache) {
        List<PostModel>? cachedPosts = CacheService.getCachedPosts('feed');
        if (cachedPosts != null) {
          return cachedPosts;
        }
      }
      
      // Query Firebase
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      List<PostModel> posts = snapshot.docs
          .map((doc) {
            try {
              return PostModel.fromMap(
                doc.data() as Map<String, dynamic>, 
                doc.id
              );
            } catch (e) {
              print('Error parsing post ${doc.id}: $e');
              return null;
            }
          })
          .where((post) => post != null)
          .cast<PostModel>()
          .toList();
      
      // Cache kết quả
      CacheService.cachePosts('feed', posts);
      
      return posts;
    } on FirebaseException catch (e) {
      print('Firebase error: ${e.message}');
      throw FirebaseException('Unable to load posts from server');
    } catch (e) {
      print('Unexpected error: $e');
      throw NetworkException('Network error occurred');
    }
  }
}
```

### 7.3 Error UI Components

```dart
// File: lib/widgets/error_widgets.dart
class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  
  const ErrorRetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  
  const NetworkErrorWidget({super.key, required this.onRetry});
  
  @override
  Widget build(BuildContext context) {
    return ErrorRetryWidget(
      message: 'No internet connection.\nPlease check your network and try again.',
      onRetry: onRetry,
    );
  }
}
```

---

## 8. CACHE VÀ OFFLINE SUPPORT

### 8.1 Firestore Offline Settings

```dart
// File: lib/main.dart - Setup offline support
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(MyApp());
}
```

### 8.2 Check Connection Status

```dart
// File: lib/services/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  
  /// Kiểm tra trạng thái kết nối hiện tại
  static Future<bool> isConnected() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  /// Stream theo dõi thay đổi kết nối
  static Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
}
```

### 8.3 Offline-First Data Loading

```dart
// File: lib/services/offline_first_service.dart
class OfflineFirstPostService {
  /// Load posts với offline-first approach
  static Future<List<PostModel>> getPostsOfflineFirst() async {
    try {
      // 1. Luôn trả về cache trước (instant loading)
      List<PostModel>? cachedPosts = CacheService.getCachedPosts('feed');
      
      // 2. Kiểm tra kết nối mạng
      bool isConnected = await ConnectivityService.isConnected();
      
      if (!isConnected && cachedPosts != null) {
        // Offline và có cache - trả về cache
        return cachedPosts;
      }
      
      // 3. Có mạng - load từ Firebase
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(const GetOptions(source: Source.server)); // Force server
      
      List<PostModel> freshPosts = snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
      
      // 4. Update cache với data mới
      CacheService.cachePosts('feed', freshPosts);
      
      return freshPosts;
    } catch (e) {
      // 5. Nếu có lỗi và có cache - trả về cache
      List<PostModel>? cachedPosts = CacheService.getCachedPosts('feed');
      if (cachedPosts != null) {
        return cachedPosts;
      }
      
      // 6. Không có cache và có lỗi - throw exception
      rethrow;
    }
  }
}
```

---

## 9. VÍ DỤ ÁP DỤNG VÀO PROJECT

### 9.1 Cấu trúc thư mục project hiện tại
```
lib/
├── features/
│   ├── auth/                 # ✅ Đã có
│   │   ├── screens/
│   │   └── widgets/
│   ├── profile/              # ✅ Đã có - CẦN CẬP NHẬT
│   │   └── main_profile.dart
│   ├── feed_Screen/          # ✅ Đã có - CẦN IMPLEMENT
│   │   └── main_feed.dart
│   └── createpost/           # ✅ Đã có - CẦN IMPLEMENT
├── models/
│   └── user_model.dart       # ✅ Đã có
├── services/
│   └── auth_service.dart     # ✅ Đã có
└── main.dart                 # ✅ Đã có
```

### 9.2 Files cần tạo mới

```
lib/
├── models/
│   └── post_model.dart       # 🆕 CẦN TẠO
├── services/
│   ├── user_service.dart     # 🆕 CẦN TẠO
│   ├── post_service.dart     # 🆕 CẦN TẠO
│   └── storage_service.dart  # 🆕 CẦN TẠO (cho upload ảnh)
└── features/
    ├── profile/
    │   └── widgets/
    │       ├── user_profile_card.dart  # 🆕 CẦN TẠO
    │       └── user_posts_grid.dart    # 🆕 CẦN TẠO
    └── feed_Screen/
        └── widgets/
            ├── post_card.dart          # 🆕 CẦN TẠO
            └── post_list.dart          # 🆕 CẦN TẠO
```

### 9.3 Áp dụng UserModel hiện tại của bạn

Sử dụng UserModel đã có trong project:
```dart
// File: lib/models/user_model.dart (ĐÃ CÓ - KHÔNG CẦN SỬA)
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
  
  // Constructor và methods đã có...
}
```

### 9.4 Tạo PostModel cho project

```dart
// File: lib/models/post_model.dart - CẦN TẠO MỚI
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> imageUrls;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> hashtags;
  final String location;
  final List<String> likedBy;
  
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
  
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      location: map['location'] ?? '',
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'hashtags': hashtags,
      'location': location,
      'likedBy': likedBy,
    };
  }
}
```

### 9.5 Cập nhật main_profile.dart hiện tại

```dart
// File: lib/features/profile/main_profile.dart - CẬP NHẬT
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart'; // 🆕 IMPORT MỚI
import '../../models/user_model.dart';
import 'widgets/user_profile_card.dart';     // 🆕 IMPORT MỚI
import 'widgets/user_posts_grid.dart';      // 🆕 IMPORT MỚI

class MainProfile extends StatefulWidget {
  const MainProfile({super.key});

  @override
  State<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends State<MainProfile> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// Load thông tin user hiện tại từ Firestore
  Future<void> _loadCurrentUser() async {
    try {
      String? uid = AuthService.currentUser?.uid;
      if (uid != null) {
        UserModel? user = await UserService.getCurrentUserProfile(uid);
        if (mounted) {
          setState(() {
            currentUser = user;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unable to load profile'),
              ElevatedButton(
                onPressed: _loadCurrentUser,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser!.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrentUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // User Profile Card
              UserProfileCard(user: currentUser!),
              
              const SizedBox(height: 16),
              
              // User Posts Grid
              UserPostsGrid(userId: currentUser!.uid),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 9.6 Cập nhật main_feed.dart hiện tại

```dart
// File: lib/features/feed_Screen/main_feed.dart - CẬP NHẬT
import 'package:flutter/material.dart';
import '../../services/post_service.dart';    // 🆕 IMPORT MỚI
import '../../models/post_model.dart';        // 🆕 IMPORT MỚI
import 'widgets/post_list.dart';              // 🆕 IMPORT MỚI

class MainFeed extends StatefulWidget {
  const MainFeed({super.key});

  @override
  State<MainFeed> createState() => _MainFeedState();
}

class _MainFeedState extends State<MainFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: const PostList(), // 🆕 Widget mới
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create post
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 9.7 Tạo UserService cho project

```dart
// File: lib/services/user_service.dart - TẠO MỚI
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Lấy profile user hiện tại (tương thích với AuthService hiện có)
  static Future<UserModel?> getCurrentUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Stream cho real-time updates (tương thích với AuthWrapper)
  static Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    });
  }
  
  /// Update profile (tương thích với AuthService.updateProfile)
  static Future<String> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoURL,
    List<String>? interests,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updateData['displayName'] = displayName.trim();
      if (bio != null) updateData['bio'] = bio.trim();
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (interests != null) updateData['interests'] = interests;
      
      await _firestore.collection('users').doc(uid).update(updateData);
      return 'success';
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
  
  /// Tìm kiếm users (cho tính năng search)
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('userName', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
```

### 9.8 Tạo PostService cho project

```dart
// File: lib/services/post_service.dart - TẠO MỚI
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Lấy danh sách posts cho feed chính
  static Future<List<PostModel>> getFeedPosts({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Lấy posts của một user cụ thể (cho profile)
  static Future<List<PostModel>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// LẤY 1 POST CỤ THỂ
  /// Sử dụng khi cần hiển thị chi tiết post
  static Future<PostModel?> getPostById(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return PostModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }
  
  /// LẤY POSTS THEO HASHTAG
  /// Sử dụng cho tính năng tìm kiếm hashtag
  static Future<List<PostModel>> getPostsByHashtag(String hashtag, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('hashtags', arrayContains: hashtag.toLowerCase())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error getting posts by hashtag: $e');
      return [];
    }
  }
  
  /// STREAM CHO REAL-TIME POSTS
  /// Tự động cập nhật khi có post mới
  static Stream<List<PostModel>> getFeedPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    });
  }
  
  /// Tạo post mới
  static Future<String> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String content,
    List<String> imageUrls = const [],
    List<String> hashtags = const [],
    String location = '',
  }) async {
    try {
      PostModel newPost = PostModel(
        id: '', // Firestore sẽ tự tạo
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        imageUrls: imageUrls,
        hashtags: hashtags,
        location: location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('posts').add(newPost.toMap());
      return 'success';
    } catch (e) {
      return 'Failed to create post: $e';
    }
  }
  
  /// Like/Unlike post
  static Future<String> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);
        
        if (!snapshot.exists) {
          throw Exception('Post does not exist');
        }
        
        List<String> likedBy = List<String>.from(snapshot.data()!['likedBy'] ?? []);
        int likes = snapshot.data()!['likes'] ?? 0;
        
        if (likedBy.contains(userId)) {
          // Unlike
          likedBy.remove(userId);
          likes = likes > 0 ? likes - 1 : 0;
        } else {
          // Like
          likedBy.add(userId);
          likes++;
        }
        
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': likes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      return 'success';
    } catch (e) {
      return 'Failed to toggle like: $e';
    }
  }
}
```

---

## 10. HƯỚNG DẪN THỰC HIỆN TỪNG BƯỚC

### BƯỚC 1: Chuẩn bị Firebase Firestore

#### 1.1 Tạo Collections trong Firebase Console
```
1. Mở Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào "Firestore Database"
4. Tạo collection "posts" (nếu chưa có)
5. Thêm 1 document test để tạo collection:
   - Document ID: test_post
   - Fields:
     authorId: "test_user"
     authorName: "Test User"
     content: "This is a test post"
     createdAt: [timestamp hiện tại]
     likes: 0
     imageUrls: []
     hashtags: []
```

#### 1.2 Kiểm tra Security Rules
```javascript
// Trong Firebase Console > Firestore > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
```

### BƯỚC 2: Tạo các file cần thiết

#### 2.1 Tạo PostModel
```bash
# Tạo file trong thư mục models
touch lib/models/post_model.dart
```
Copy code PostModel từ mục 9.4 vào file này.

#### 2.2 Tạo Services
```bash
# Tạo các service files
touch lib/services/user_service.dart
touch lib/services/post_service.dart
```
Copy code từ mục 9.7 và 9.8.

#### 2.3 Tạo Widget folders
```bash
# Tạo thư mục widgets
mkdir -p lib/features/profile/widgets
mkdir -p lib/features/feed_Screen/widgets
```

### BƯỚC 3: Tạo UI Widgets

#### 3.1 UserProfileCard Widget
```dart
// File: lib/features/profile/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;
  
  const UserProfileCard({super.key, required this.user});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: user.photoURL.isNotEmpty 
                  ? NetworkImage(user.photoURL)
                  : null,
              child: user.photoURL.isEmpty 
                  ? Text(
                      user.displayName.isNotEmpty 
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Display Name & Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 24,
                  ),
                ],
              ],
            ),
            
            // Username
            Text(
              '@${user.userName}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Bio
            if (user.bio.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.bio,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', 0), // TODO: Implement post count
                _buildStatColumn('Followers', user.followers),
                _buildStatColumn('Following', user.following),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Interests
            if (user.interests.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(color: Colors.blue),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
```

#### 3.2 UserPostsGrid Widget
```dart
// File: lib/features/profile/widgets/user_posts_grid.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';

class UserPostsGrid extends StatefulWidget {
  final String userId;
  
  const UserPostsGrid({super.key, required this.userId});
  
  @override
  State<UserPostsGrid> createState() => _UserPostsGridState();
}

class _UserPostsGridState extends State<UserPostsGrid> {
  List<PostModel> posts = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }
  
  Future<void> _loadUserPosts() async {
    try {
      List<PostModel> userPosts = await PostService.getUserPosts(widget.userId);
      if (mounted) {
        setState(() {
          posts = userPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No posts yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Posts (${posts.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            PostModel post = posts[index];
            return GestureDetector(
              onTap: () {
                // TODO: Navigate to post detail
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: post.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          post.content,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

#### 3.3 PostList Widget cho Feed
```dart
// File: lib/features/feed_Screen/widgets/post_list.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});
  
  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  List<PostModel> posts = [];
  bool isLoading = true;
  bool hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }
  
  /// Load posts từ Firebase
  Future<void> _loadPosts() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      List<PostModel> feedPosts = await PostService.getFeedPosts();
      
      if (mounted) {
        setState(() {
          posts = feedPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Error state
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Unable to load posts'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Empty state
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts available'),
            SizedBox(height: 8),
            Text('Be the first to share something!', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Success state - hiển thị danh sách posts
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }
}
```

#### 3.4 PostCard Widget
```dart
// File: lib/features/feed_Screen/widgets/post_card.dart
import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final PostModel post;
  
  const PostCard({super.key, required this.post});
  
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likesCount;
  bool isLiking = false;
  
  @override
  void initState() {
    super.initState();
    String? currentUserId = AuthService.currentUser?.uid;
    isLiked = currentUserId != null && widget.post.likedBy.contains(currentUserId);
    likesCount = widget.post.likes;
  }
  
  Future<void> _toggleLike() async {
    if (isLiking) return;
    
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return;
    
    setState(() => isLiking = true);
    
    // Optimistic update
    setState(() {
      if (isLiked) {
        likesCount--;
        isLiked = false;
      } else {
        likesCount++;
        isLiked = true;
      }
    });
    
    String result = await PostService.toggleLike(widget.post.id, currentUserId);
    
    if (result != 'success') {
      // Revert on error
      setState(() {
        if (isLiked) {
          likesCount--;
          isLiked = false;
        } else {
          likesCount++;
          isLiked = true;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    }
    
    setState(() => isLiking = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.authorAvatar.isNotEmpty 
                  ? NetworkImage(widget.post.authorAvatar)
                  : null,
              child: widget.post.authorAvatar.isEmpty 
                  ? Text(widget.post.authorName.isNotEmpty 
                      ? widget.post.authorName[0].toUpperCase() 
                      : 'U')
                  : null,
            ),
            title: Text(
              widget.post.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(timeago.format(widget.post.createdAt)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show post options
              },
            ),
          ),
          
          // Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          
          // Images
          if (widget.post.imageUrls.isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: PageView.builder(
                itemCount: widget.post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.post.imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Location
          if (widget.post.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.post.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          // Hashtags
          if (widget.post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.post.hashtags.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to hashtag posts
                    },
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likesCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Navigate to comments
                  },
                ),
                Text('${widget.post.comments}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Handle share
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 9. VÍ DỤ ÁP DỤNG VÀO PROJECT

### 9.1 Cấu trúc thư mục project hiện tại
```
lib/
├── features/
│   ├── auth/                 # ✅ Đã có
│   │   ├── screens/
│   │   └── widgets/
│   ├── profile/              # ✅ Đã có - CẦN CẬP NHẬT
│   │   └── main_profile.dart
│   ├── feed_Screen/          # ✅ Đã có - CẦN IMPLEMENT
│   │   └── main_feed.dart
│   └── createpost/           # ✅ Đã có - CẦN IMPLEMENT
├── models/
│   └── user_model.dart       # ✅ Đã có
├── services/
│   └── auth_service.dart     # ✅ Đã có
└── main.dart                 # ✅ Đã có
```

### 9.2 Files cần tạo mới

```
lib/
├── models/
│   └── post_model.dart       # 🆕 CẦN TẠO
├── services/
│   ├── user_service.dart     # 🆕 CẦN TẠO
│   ├── post_service.dart     # 🆕 CẦN TẠO
│   └── storage_service.dart  # 🆕 CẦN TẠO (cho upload ảnh)
└── features/
    ├── profile/
    │   └── widgets/
    │       ├── user_profile_card.dart  # 🆕 CẦN TẠO
    │       └── user_posts_grid.dart    # 🆕 CẦN TẠO
    └── feed_Screen/
        └── widgets/
            ├── post_card.dart          # 🆕 CẦN TẠO
            └── post_list.dart          # 🆕 CẦN TẠO
```

### 9.3 Áp dụng UserModel hiện tại của bạn

Sử dụng UserModel đã có trong project:
```dart
// File: lib/models/user_model.dart (ĐÃ CÓ - KHÔNG CẦN SỬA)
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
  
  // Constructor và methods đã có...
}
```

### 9.4 Tạo PostModel cho project

```dart
// File: lib/models/post_model.dart - CẦN TẠO MỚI
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> imageUrls;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> hashtags;
  final String location;
  final List<String> likedBy;
  
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
  
  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      hashtags: List<String>.from(map['hashtags'] ?? []),
      location: map['location'] ?? '',
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'imageUrls': imageUrls,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'hashtags': hashtags,
      'location': location,
      'likedBy': likedBy,
    };
  }
}
```

### 9.5 Cập nhật main_profile.dart hiện tại

```dart
// File: lib/features/profile/main_profile.dart - CẬP NHẬT
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart'; // 🆕 IMPORT MỚI
import '../../models/user_model.dart';
import 'widgets/user_profile_card.dart';     // 🆕 IMPORT MỚI
import 'widgets/user_posts_grid.dart';      // 🆕 IMPORT MỚI

class MainProfile extends StatefulWidget {
  const MainProfile({super.key});

  @override
  State<MainProfile> createState() => _MainProfileState();
}

class _MainProfileState extends State<MainProfile> {
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  /// Load thông tin user hiện tại từ Firestore
  Future<void> _loadCurrentUser() async {
    try {
      String? uid = AuthService.currentUser?.uid;
      if (uid != null) {
        UserModel? user = await UserService.getCurrentUserProfile(uid);
        if (mounted) {
          setState(() {
            currentUser = user;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Unable to load profile'),
              ElevatedButton(
                onPressed: _loadCurrentUser,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser!.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCurrentUser,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // User Profile Card
              UserProfileCard(user: currentUser!),
              
              const SizedBox(height: 16),
              
              // User Posts Grid
              UserPostsGrid(userId: currentUser!.uid),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 9.6 Cập nhật main_feed.dart hiện tại

```dart
// File: lib/features/feed_Screen/main_feed.dart - CẬP NHẬT
import 'package:flutter/material.dart';
import '../../services/post_service.dart';    // 🆕 IMPORT MỚI
import '../../models/post_model.dart';        // 🆕 IMPORT MỚI
import 'widgets/post_list.dart';              // 🆕 IMPORT MỚI

class MainFeed extends StatefulWidget {
  const MainFeed({super.key});

  @override
  State<MainFeed> createState() => _MainFeedState();
}

class _MainFeedState extends State<MainFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: const PostList(), // 🆕 Widget mới
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create post
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 9.7 Tạo UserService cho project

```dart
// File: lib/services/user_service.dart - TẠO MỚI
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Lấy profile user hiện tại (tương thích với AuthService hiện có)
  static Future<UserModel?> getCurrentUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Stream cho real-time updates (tương thích với AuthWrapper)
  static Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    });
  }
  
  /// Update profile (tương thích với AuthService.updateProfile)
  static Future<String> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoURL,
    List<String>? interests,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updateData['displayName'] = displayName.trim();
      if (bio != null) updateData['bio'] = bio.trim();
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (interests != null) updateData['interests'] = interests;
      
      await _firestore.collection('users').doc(uid).update(updateData);
      return 'success';
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }
  
  /// Tìm kiếm users (cho tính năng search)
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('userName', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(20)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
```

### 9.8 Tạo PostService cho project

```dart
// File: lib/services/post_service.dart - TẠO MỚI
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Lấy danh sách posts cho feed chính
  static Future<List<PostModel>> getFeedPosts({int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Lấy posts của một user cụ thể (cho profile)
  static Future<List<PostModel>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// LẤY 1 POST CỤ THỂ
  /// Sử dụng khi cần hiển thị chi tiết post
  static Future<PostModel?> getPostById(String postId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return PostModel.fromMap(
          doc.data() as Map<String, dynamic>, 
          doc.id
        );
      }
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }
  
  /// LẤY POSTS THEO HASHTAG
  /// Sử dụng cho tính năng tìm kiếm hashtag
  static Future<List<PostModel>> getPostsByHashtag(String hashtag, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('hashtags', arrayContains: hashtag.toLowerCase())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    } catch (e) {
      print('Error getting posts by hashtag: $e');
      return [];
    }
  }
  
  /// STREAM CHO REAL-TIME POSTS
  /// Tự động cập nhật khi có post mới
  static Stream<List<PostModel>> getFeedPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PostModel.fromMap(
              doc.data() as Map<String, dynamic>, 
              doc.id
            ))
          .toList();
    });
  }
  
  /// Tạo post mới
  static Future<String> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String content,
    List<String> imageUrls = const [],
    List<String> hashtags = const [],
    String location = '',
  }) async {
    try {
      PostModel newPost = PostModel(
        id: '', // Firestore sẽ tự tạo
        authorId: authorId,
        authorName: authorName,
        authorAvatar: authorAvatar,
        content: content,
        imageUrls: imageUrls,
        hashtags: hashtags,
        location: location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('posts').add(newPost.toMap());
      return 'success';
    } catch (e) {
      return 'Failed to create post: $e';
    }
  }
  
  /// Like/Unlike post
  static Future<String> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);
        
        if (!snapshot.exists) {
          throw Exception('Post does not exist');
        }
        
        List<String> likedBy = List<String>.from(snapshot.data()!['likedBy'] ?? []);
        int likes = snapshot.data()!['likes'] ?? 0;
        
        if (likedBy.contains(userId)) {
          // Unlike
          likedBy.remove(userId);
          likes = likes > 0 ? likes - 1 : 0;
        } else {
          // Like
          likedBy.add(userId);
          likes++;
        }
        
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likes': likes,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      
      return 'success';
    } catch (e) {
      return 'Failed to toggle like: $e';
    }
  }
}
```

---

## 10. HƯỚNG DẪN THỰC HIỆN TỪNG BƯỚC

### BƯỚC 1: Chuẩn bị Firebase Firestore

#### 1.1 Tạo Collections trong Firebase Console
```
1. Mở Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào "Firestore Database"
4. Tạo collection "posts" (nếu chưa có)
5. Thêm 1 document test để tạo collection:
   - Document ID: test_post
   - Fields:
     authorId: "test_user"
     authorName: "Test User"
     content: "This is a test post"
     createdAt: [timestamp hiện tại]
     likes: 0
     imageUrls: []
     hashtags: []
```

#### 1.2 Kiểm tra Security Rules
```javascript
// Trong Firebase Console > Firestore > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
```

### BƯỚC 2: Tạo các file cần thiết

#### 2.1 Tạo PostModel
```bash
# Tạo file trong thư mục models
touch lib/models/post_model.dart
```
Copy code PostModel từ mục 9.4 vào file này.

#### 2.2 Tạo Services
```bash
# Tạo các service files
touch lib/services/user_service.dart
touch lib/services/post_service.dart
```
Copy code từ mục 9.7 và 9.8.

#### 2.3 Tạo Widget folders
```bash
# Tạo thư mục widgets
mkdir -p lib/features/profile/widgets
mkdir -p lib/features/feed_Screen/widgets
```

### BƯỚC 3: Tạo UI Widgets

#### 3.1 UserProfileCard Widget
```dart
// File: lib/features/profile/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;
  
  const UserProfileCard({super.key, required this.user});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: user.photoURL.isNotEmpty 
                  ? NetworkImage(user.photoURL)
                  : null,
              child: user.photoURL.isEmpty 
                  ? Text(
                      user.displayName.isNotEmpty 
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Display Name & Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 24,
                  ),
                ],
              ],
            ),
            
            // Username
            Text(
              '@${user.userName}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Bio
            if (user.bio.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.bio,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', 0), // TODO: Implement post count
                _buildStatColumn('Followers', user.followers),
                _buildStatColumn('Following', user.following),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Interests
            if (user.interests.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(color: Colors.blue),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
```

#### 3.2 UserPostsGrid Widget
```dart
// File: lib/features/profile/widgets/user_posts_grid.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';

class UserPostsGrid extends StatefulWidget {
  final String userId;
  
  const UserPostsGrid({super.key, required this.userId});
  
  @override
  State<UserPostsGrid> createState() => _UserPostsGridState();
}

class _UserPostsGridState extends State<UserPostsGrid> {
  List<PostModel> posts = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }
  
  Future<void> _loadUserPosts() async {
    try {
      List<PostModel> userPosts = await PostService.getUserPosts(widget.userId);
      if (mounted) {
        setState(() {
          posts = userPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No posts yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Posts (${posts.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            PostModel post = posts[index];
            return GestureDetector(
              onTap: () {
                // TODO: Navigate to post detail
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: post.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          post.content,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

#### 3.3 PostList Widget cho Feed
```dart
// File: lib/features/feed_Screen/widgets/post_list.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});
  
  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  List<PostModel> posts = [];
  bool isLoading = true;
  bool hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }
  
  /// Load posts từ Firebase
  Future<void> _loadPosts() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      List<PostModel> feedPosts = await PostService.getFeedPosts();
      
      if (mounted) {
        setState(() {
          posts = feedPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Error state
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Unable to load posts'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Empty state
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts available'),
            SizedBox(height: 8),
            Text('Be the first to share something!', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Success state - hiển thị danh sách posts
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }
}
```

#### 3.4 PostCard Widget
```dart
// File: lib/features/feed_Screen/widgets/post_card.dart
import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final PostModel post;
  
  const PostCard({super.key, required this.post});
  
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likesCount;
  bool isLiking = false;
  
  @override
  void initState() {
    super.initState();
    String? currentUserId = AuthService.currentUser?.uid;
    isLiked = currentUserId != null && widget.post.likedBy.contains(currentUserId);
    likesCount = widget.post.likes;
  }
  
  Future<void> _toggleLike() async {
    if (isLiking) return;
    
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return;
    
    setState(() => isLiking = true);
    
    // Optimistic update
    setState(() {
      if (isLiked) {
        likesCount--;
        isLiked = false;
      } else {
        likesCount++;
        isLiked = true;
      }
    });
    
    String result = await PostService.toggleLike(widget.post.id, currentUserId);
    
    if (result != 'success') {
      // Revert on error
      setState(() {
        if (isLiked) {
          likesCount--;
          isLiked = false;
        } else {
          likesCount++;
          isLiked = true;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    }
    
    setState(() => isLiking = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.authorAvatar.isNotEmpty 
                  ? NetworkImage(widget.post.authorAvatar)
                  : null,
              child: widget.post.authorAvatar.isEmpty 
                  ? Text(widget.post.authorName.isNotEmpty 
                      ? widget.post.authorName[0].toUpperCase() 
                      : 'U')
                  : null,
            ),
            title: Text(
              widget.post.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(timeago.format(widget.post.createdAt)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show post options
              },
            ),
          ),
          
          // Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          
          // Images
          if (widget.post.imageUrls.isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: PageView.builder(
                itemCount: widget.post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.post.imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Location
          if (widget.post.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.post.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          // Hashtags
          if (widget.post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.post.hashtags.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to hashtag posts
                    },
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likesCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Navigate to comments
                  },
                ),
                Text('${widget.post.comments}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Handle share
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 10. HƯỚNG DẪN THỰC HIỆN TỪNG BƯỚC

### BƯỚC 1: Chuẩn bị Firebase Firestore

#### 1.1 Tạo Collections trong Firebase Console
```
1. Mở Firebase Console: https://console.firebase.google.com
2. Chọn project của bạn
3. Vào "Firestore Database"
4. Tạo collection "posts" (nếu chưa có)
5. Thêm 1 document test để tạo collection:
   - Document ID: test_post
   - Fields:
     authorId: "test_user"
     authorName: "Test User"
     content: "This is a test post"
     createdAt: [timestamp hiện tại]
     likes: 0
     imageUrls: []
     hashtags: []
```

#### 1.2 Kiểm tra Security Rules
```javascript
// Trong Firebase Console > Firestore > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
```

### BƯỚC 2: Tạo các file cần thiết

#### 2.1 Tạo PostModel
```bash
# Tạo file trong thư mục models
touch lib/models/post_model.dart
```
Copy code PostModel từ mục 9.4 vào file này.

#### 2.2 Tạo Services
```bash
# Tạo các service files
touch lib/services/user_service.dart
touch lib/services/post_service.dart
```
Copy code từ mục 9.7 và 9.8.

#### 2.3 Tạo Widget folders
```bash
# Tạo thư mục widgets
mkdir -p lib/features/profile/widgets
mkdir -p lib/features/feed_Screen/widgets
```

### BƯỚC 3: Tạo UI Widgets

#### 3.1 UserProfileCard Widget
```dart
// File: lib/features/profile/widgets/user_profile_card.dart
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;
  
  const UserProfileCard({super.key, required this.user});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundImage: user.photoURL.isNotEmpty 
                  ? NetworkImage(user.photoURL)
                  : null,
              child: user.photoURL.isEmpty 
                  ? Text(
                      user.displayName.isNotEmpty 
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            
            // Display Name & Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 24,
                  ),
                ],
              ],
            ),
            
            // Username
            Text(
              '@${user.userName}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Bio
            if (user.bio.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.bio,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Posts', 0), // TODO: Implement post count
                _buildStatColumn('Followers', user.followers),
                _buildStatColumn('Following', user.following),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Interests
            if (user.interests.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.interests.map((interest) {
                  return Chip(
                    label: Text(interest),
                    backgroundColor: Colors.blue[50],
                    labelStyle: const TextStyle(color: Colors.blue),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
```

#### 3.2 UserPostsGrid Widget
```dart
// File: lib/features/profile/widgets/user_posts_grid.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';

class UserPostsGrid extends StatefulWidget {
  final String userId;
  
  const UserPostsGrid({super.key, required this.userId});
  
  @override
  State<UserPostsGrid> createState() => _UserPostsGridState();
}

class _UserPostsGridState extends State<UserPostsGrid> {
  List<PostModel> posts = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }
  
  Future<void> _loadUserPosts() async {
    try {
      List<PostModel> userPosts = await PostService.getUserPosts(widget.userId);
      if (mounted) {
        setState(() {
          posts = userPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No posts yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Posts (${posts.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            PostModel post = posts[index];
            return GestureDetector(
              onTap: () {
                // TODO: Navigate to post detail
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: post.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrls.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.error));
                          },
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          post.content,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

#### 3.3 PostList Widget cho Feed
```dart
// File: lib/features/feed_Screen/widgets/post_list.dart
import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';
import 'post_card.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});
  
  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  List<PostModel> posts = [];
  bool isLoading = true;
  bool hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }
  
  /// Load posts từ Firebase
  Future<void> _loadPosts() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      List<PostModel> feedPosts = await PostService.getFeedPosts();
      
      if (mounted) {
        setState(() {
          posts = feedPosts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Error state
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Unable to load posts'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Empty state
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No posts available'),
            SizedBox(height: 8),
            Text('Be the first to share something!', 
                 style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Success state - hiển thị danh sách posts
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: posts[index]);
        },
      ),
    );
  }
}
```

#### 3.4 PostCard Widget
```dart
// File: lib/features/feed_Screen/widgets/post_card.dart
import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/post_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final PostModel post;
  
  const PostCard({super.key, required this.post});
  
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;
  late int likesCount;
  bool isLiking = false;
  
  @override
  void initState() {
    super.initState();
    String? currentUserId = AuthService.currentUser?.uid;
    isLiked = currentUserId != null && widget.post.likedBy.contains(currentUserId);
    likesCount = widget.post.likes;
  }
  
  Future<void> _toggleLike() async {
    if (isLiking) return;
    
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return;
    
    setState(() => isLiking = true);
    
    // Optimistic update
    setState(() {
      if (isLiked) {
        likesCount--;
        isLiked = false;
      } else {
        likesCount++;
        isLiked = true;
      }
    });
    
    String result = await PostService.toggleLike(widget.post.id, currentUserId);
    
    if (result != 'success') {
      // Revert on error
      setState(() {
        if (isLiked) {
          likesCount--;
          isLiked = false;
        } else {
          likesCount++;
          isLiked = true;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like')),
        );
      }
    }
    
    setState(() => isLiking = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.authorAvatar.isNotEmpty 
                  ? NetworkImage(widget.post.authorAvatar)
                  : null,
              child: widget.post.authorAvatar.isEmpty 
                  ? Text(widget.post.authorName.isNotEmpty 
                      ? widget.post.authorName[0].toUpperCase() 
                      : 'U')
                  : null,
            ),
            title: Text(
              widget.post.authorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(timeago.format(widget.post.createdAt)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show post options
              },
            ),
          ),
          
          // Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          
          // Images
          if (widget.post.imageUrls.isNotEmpty)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: PageView.builder(
                itemCount: widget.post.imageUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.post.imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.error, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Location
          if (widget.post.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.post.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          
          // Hashtags
          if (widget.post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.post.hashtags.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to hashtag posts
                    },
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$likesCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Navigate to comments
                  },
                ),
                Text('${widget.post.comments}'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  onPressed: () {
                    // TODO: Handle share
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 11. BEST PRACTICES

### 11.1 Performance Optimization

```dart
// 1. Sử dụng pagination thay vì load tất cả
// 2. Cache frequently accessed data
// 3. Use indexed queries in Firestore
// 4. Lazy loading cho images
// 5. Dispose streams properly

class OptimizedPostCard extends StatefulWidget {
  final PostModel post;
  const OptimizedPostCard({super.key, required this.post});
  
  @override
  State<OptimizedPostCard> createState() => _OptimizedPostCardState();
}

class _OptimizedPostCardState extends State<OptimizedPostCard> 
    with AutomaticKeepAliveClientMixin {
  
  // Keep widget alive khi scroll
  @override
  bool get wantKeepAlive => true;
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Card(
      child: Column(
        children: [
          // Sử dụng cached_network_image cho performance tốt hơn
          if (widget.post.imageUrls.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.post.imageUrls.first,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
              height: 200,
            ),
          // ... rest of the widget
        ],
      ),
    );
  }
}
```

### 11.2 Security Rules Examples

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true; // Public read
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Posts collection
    match /posts/{postId} {
      allow read: if true; // Public read
      allow create: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
```

### 11.3 Testing Data Loading

```dart
// File: test/services/post_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('PostService Tests', () {
    test('should return empty list when no posts exist', () async {
      // Arrange
      MockFirebaseFirestore mockFirestore = MockFirebaseFirestore();
      when(mockFirestore.collection('posts')).thenReturn(mockCollection);
      
      // Act
      List<PostModel> posts = await PostService.getFeedPosts();
      
      // Assert
      expect(posts, isEmpty);
    });
    
    test('should handle network errors gracefully', () async {
      // Test error handling
    });
  });
}
```

---

## 12. TROUBLESHOOTING

### Lỗi thường gặp:

1. **"Field does not exist"**
   - Kiểm tra tên field trong Firestore
   - Sử dụng null safety (`map['field'] ?? defaultValue`)

2. **"Index not found"**
   - Tạo composite index trong Firebase Console
   - Chỉ query với indexed fields

3. **"Permission denied"**
   - Kiểm tra Firestore Security Rules
   - Đảm bảo user đã authenticate

4. **"Network error"**
   - Implement offline support
   - Sử dụng try-catch cho tất cả Firebase calls

5. **Performance issues**
   - Sử dụng pagination
   - Cache frequently accessed data
   - Optimize image loading

---

