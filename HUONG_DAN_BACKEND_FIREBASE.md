# HƯỚNG DẪN TRIỂN KHAI BACKEND VÀ DATABASE FIREBASE CHO SOCIAL MEDIA APP

## 1. TỔNG QUAN VỀ FIREBASE

Firebase là một nền tảng Backend-as-a-Service (BaaS) của Google cung cấp các dịch vụ backend sẵn có:

### 1.1 Các dịch vụ Firebase chính sử dụng trong project:
- **Firebase Auth**: Xác thực người dùng (đăng ký, đăng nhập, quên mật khẩu)
- **Cloud Firestore**: Database NoSQL để lưu trữ dữ liệu
- **Firebase Storage**: Lưu trữ hình ảnh, video
- **Firebase Functions**: Chạy code backend trên server (tùy chọn)

### 1.2 Ưu điểm Firebase:
- Real-time database (cập nhật dữ liệu theo thời gian thực)
- Tự động scaling
- Bảo mật tích hợp
- Dễ tích hợp với Flutter

## 2. CẤU TRÚC DATABASE FIRESTORE

### 2.1 Hiểu về NoSQL Database:
- Khác với SQL (MySQL, PostgreSQL), Firestore là NoSQL
- Dữ liệu được tổ chức theo **Collections** và **Documents**
- Mỗi Document chứa các **Fields** (key-value pairs)
- Có thể có **Subcollections** trong Documents

### 2.2 Cấu trúc đề xuất cho Social Media App:

```
📁 users (collection)
  📄 userId1 (document)
    - email: "user@example.com"
    - displayName: "Nguyen Van A"
    - photoURL: "https://..."
    - bio: "Mô tả bản thân"
    - followers: 100
    - following: 50
    - createdAt: timestamp
    
📁 posts (collection)
  📄 postId1 (document)
    - authorId: "userId1"
    - content: "Nội dung bài viết"
    - imageUrls: ["url1", "url2"]
    - likes: 25
    - comments: 5
    - createdAt: timestamp
    - updatedAt: timestamp
    
    📁 comments (subcollection)
      📄 commentId1 (document)
        - authorId: "userId2"
        - content: "Bình luận hay quá!"
        - createdAt: timestamp
        
📁 chats (collection)
  📄 chatId1 (document)
    - participants: ["userId1", "userId2"]
    - lastMessage: "Tin nhắn cuối"
    - lastMessageTime: timestamp
    
    📁 messages (subcollection)
      📄 messageId1 (document)
        - senderId: "userId1"
        - content: "Xin chào!"
        - type: "text" // hoặc "image"
        - timestamp: timestamp
```

## 3. FIREBASE AUTHENTICATION - LOGIC CHI TIẾT

### 3.1 Cách thức hoạt động:
1. **Đăng ký**: User nhập email/password → Firebase tạo tài khoản → Trả về User ID
2. **Đăng nhập**: Firebase kiểm tra thông tin → Trả về Auth Token
3. **Auth Token**: Được sử dụng cho mọi request sau đó để xác thực

### 3.2 Security Rules:
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chỉ user đã đăng nhập mới được đọc/ghi dữ liệu của chính họ
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Posts có thể đọc public, nhưng chỉ tác giả mới được sửa/xóa
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.authorId == request.auth.uid;
    }
  }
}
```

## 4. CÁC FILE BACKEND CẦN TẠO

### 4.1 File Services (Tầng logic backend):

#### A. auth_service.dart (CẢI TIẾN)
```dart
// Xử lý tất cả logic xác thực
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Đăng ký tài khoản mới
  static Future<UserCredential?> signUp(String email, String password, String displayName) async {
    try {
      // Tạo tài khoản Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Tạo document user trong Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'photoURL': '',
        'bio': '',
        'followers': 0,
        'following': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      print('Lỗi đăng ký: $e');
      return null;
    }
  }
  
  // Đăng nhập
  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      return null;
    }
  }
  
  // Đăng xuất
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Lấy user hiện tại
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
```

#### B. user_service.dart
```dart
// Xử lý logic liên quan đến user data
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Lấy thông tin user
  static Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Lỗi lấy user: $e');
      return null;
    }
  }
  
  // Cập nhật profile
  static Future<bool> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('Lỗi cập nhật profile: $e');
      return false;
    }
  }
  
  // Follow user
  static Future<bool> followUser(String currentUserId, String targetUserId) async {
    try {
      // Cập nhật following count của user hiện tại
      await _firestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.increment(1)
      });
      
      // Cập nhật followers count của user được follow
      await _firestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.increment(1)
      });
      
      return true;
    } catch (e) {
      print('Lỗi follow user: $e');
      return false;
    }
  }
}
```

#### C. post_service.dart
```dart
// Xử lý logic posts
class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Tạo bài viết mới
  static Future<bool> createPost(PostModel post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
      return true;
    } catch (e) {
      print('Lỗi tạo post: $e');
      return false;
    }
  }
  
  // Lấy danh sách posts (với pagination)
  static Stream<QuerySnapshot> getPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
  
  // Like/Unlike post
  static Future<bool> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(postRef);
        
        if (!postSnapshot.exists) {
          throw Exception("Post không tồn tại!");
        }
        
        Map<String, dynamic> postData = postSnapshot.data() as Map<String, dynamic>;
        List<dynamic> likes = postData['likedBy'] ?? [];
        
        if (likes.contains(userId)) {
          // Unlike
          likes.remove(userId);
        } else {
          // Like
          likes.add(userId);
        }
        
        transaction.update(postRef, {
          'likedBy': likes,
          'likes': likes.length,
        });
      });
      
      return true;
    } catch (e) {
      print('Lỗi toggle like: $e');
      return false;
    }
  }
}
```

#### D. storage_service.dart
```dart
// Xử lý upload hình ảnh
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload hình ảnh
  static Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('$folder/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Lỗi upload image: $e');
      return null;
    }
  }
  
  // Xóa hình ảnh
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Lỗi xóa image: $e');
      return false;
    }
  }
}
```

### 4.2 File Models (Cấu trúc dữ liệu):

#### A. user_model.dart (CẢI TIẾN)
```dart
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoURL;
  final String bio;
  final int followers;
  final int following;
  final DateTime? createdAt;
  
  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.bio = '',
    this.followers = 0,
    this.following = 0,
    this.createdAt,
  });
  
  // Chuyển từ Map sang Object
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      bio: map['bio'] ?? '',
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      createdAt: map['createdAt']?.toDate(),
    );
  }
  
  // Chuyển từ Object sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'followers': followers,
      'following': following,
      'createdAt': createdAt,
    };
  }
}
```

#### B. post_model.dart
```dart
class PostModel {
  final String? id;
  final String authorId;
  final String content;
  final List<String> imageUrls;
  final List<String> likedBy;
  final int likes;
  final int comments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  PostModel({
    this.id,
    required this.authorId,
    required this.content,
    this.imageUrls = const [],
    this.likedBy = const [],
    this.likes = 0,
    this.comments = 0,
    this.createdAt,
    this.updatedAt,
  });
  
  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'],
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'imageUrls': imageUrls,
      'likedBy': likedBy,
      'likes': likes,
      'comments': comments,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
```

## 5. LOGIC HOẠT ĐỘNG CỦA CÁC TÍNH NĂNG CHÍNH

### 5.1 Đăng ký tài khoản:
1. User nhập thông tin → Validate dữ liệu
2. Gọi `AuthService.signUp()` → Tạo tài khoản Firebase Auth
3. Tự động tạo document trong collection `users`
4. Chuyển về màn hình chính

### 5.2 Tạo bài viết:
1. User viết nội dung + chọn ảnh
2. Upload ảnh lên Firebase Storage → Nhận được URL
3. Tạo PostModel với content + imageUrls
4. Lưu vào Firestore collection `posts`
5. Real-time update feed của users khác

### 5.3 Like bài viết:
1. User nhấn nút like
2. Kiểm tra user đã like chưa trong array `likedBy`
3. Nếu chưa: thêm userId vào array, tăng count
4. Nếu rồi: xóa userId khỏi array, giảm count
5. Cập nhật real-time UI

### 5.4 Chat real-time:
1. Tạo document chat với `participants`
2. Messages lưu trong subcollection
3. Sử dụng Stream để lắng nghe tin nhắn mới
4. Cập nhật `lastMessage` trong chat document

## 6. SECURITY VÀ BEST PRACTICES

### 6.1 Security Rules quan trọng:
- Chỉ user đã auth mới được truy cập data
- User chỉ được sửa/xóa data của chính họ
- Validate dữ liệu trước khi lưu

### 6.2 Performance Optimization:
- Sử dụng pagination cho danh sách dài
- Cache dữ liệu thường xuyên sử dụng
- Optimize hình ảnh trước khi upload
- Sử dụng indices cho queries phức tạp

### 6.3 Error Handling:
- Luôn wrap Firebase calls trong try-catch
- Hiển thị thông báo lỗi thân thiện cho user
- Log lỗi để debug

## 7. CÁCH TRIỂN KHAI TỪNG BƯỚC

### Bước 1: Setup Firebase Project
1. Tạo project trên Firebase Console
2. Kích hoạt Authentication, Firestore, Storage
3. Download config files (google-services.json cho Android)

### Bước 2: Tạo các Service files
1. Tạo folder `lib/services/`
2. Implement từng service theo hướng dẫn trên

### Bước 3: Tạo Models
1. Tạo folder `lib/models/`
2. Define data structure cho User, Post, Chat

### Bước 4: Implement UI logic
1. Kết nối UI với các services
2. Sử dụng StreamBuilder cho real-time data
3. Handle loading states và errors

### Bước 5: Testing
1. Test từng chức năng trên emulator
2. Test với dữ liệu thật
3. Deploy và test production

## 8. KẾT LUẬN

Firebase cung cấp một giải pháp backend hoàn chỉnh mà không cần tự xây dựng server. Quan trọng nhất là hiểu rõ:

1. **Data modeling**: Cách tổ chức dữ liệu trong NoSQL
2. **Security**: Bảo vệ dữ liệu người dùng
3. **Real-time**: Tận dụng khả năng cập nhật thời gian thực
4. **Optimization**: Tối ưu performance và cost

Bắt đầu với những tính năng cơ bản rồi dần dần mở rộng. Firebase có thể scale từ app nhỏ đến hàng triệu users!
