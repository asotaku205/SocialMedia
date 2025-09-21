# HƯỚNG DẪN CÚ PHÁP VÀ CẤU TRÚC CODE FIREBASE CHI TIẾT

## PHẦN 1: CÚ PHÁP CƠ BẢN FIREBASE

### 1.1 Import Firebase packages:
```dart
// Luôn import những packages này ở đầu file
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
```

### 1.2 Khởi tạo Firebase instances:
```dart
class FirebaseHelper {
  // Khởi tạo instances - dùng static để truy cập toàn cục
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Getter methods để truy cập từ bên ngoài
  static FirebaseAuth get auth => _auth;
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseStorage get storage => _storage;
}
```

## PHẦN 2: CÚ PHÁP FIREBASE AUTHENTICATION

### 2.1 Cấu trúc method đăng ký:
```dart
static Future<UserCredential?> signUp({
  required String email,
  required String password,
  required String displayName,
}) async {
  try {
    // Bước 1: Tạo tài khoản trong Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Bước 2: Cập nhật display name
    await userCredential.user?.updateDisplayName(displayName);
    
    // Bước 3: Tạo document trong Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'uid': userCredential.user!.uid,
      'email': email,
      'displayName': displayName,
      'photoURL': '',
      'bio': '',
      'followers': 0,
      'following': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return userCredential;
  } on FirebaseAuthException catch (e) {
    // Xử lý lỗi cụ thể của Firebase Auth
    print('Firebase Auth Error: ${e.code} - ${e.message}');
    return null;
  } catch (e) {
    // Xử lý lỗi khác
    print('General Error: $e');
    return null;
  }
}
```

### 2.2 Cấu trúc method đăng nhập:
```dart
static Future<UserCredential?> signIn({
  required String email,
  required String password,
}) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  } on FirebaseAuthException catch (e) {
    // Các mã lỗi thường gặp:
    switch (e.code) {
      case 'user-not-found':
        print('Không tìm thấy tài khoản với email này');
        break;
      case 'wrong-password':
        print('Mật khẩu không đúng');
        break;
      case 'invalid-email':
        print('Email không hợp lệ');
        break;
      default:
        print('Lỗi đăng nhập: ${e.message}');
    }
    return null;
  }
}
```

### 2.3 Kiểm tra trạng thái đăng nhập:
```dart
// Kiểm tra user hiện tại (one-time)
static User? getCurrentUser() {
  return FirebaseAuth.instance.currentUser;
}

// Lắng nghe thay đổi trạng thái auth (realtime)
static Stream<User?> get authStateChanges {
  return FirebaseAuth.instance.authStateChanges();
}

// Sử dụng trong widget:
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator(); // Đang loading
    }
    
    if (snapshot.hasData) {
      return HomeScreen(); // User đã đăng nhập
    } else {
      return LoginScreen(); // User chưa đăng nhập
    }
  },
)
```

## PHẦN 3: CÚ PHÁP FIRESTORE DATABASE

### 3.1 Cấu trúc đường dẫn Firestore:
```dart
// Cú pháp cơ bản:
// collection('tên_collection').doc('id_document')

// Ví dụ cụ thể:
FirebaseFirestore.instance
  .collection('users')           // Collection users
  .doc('user123')               // Document có ID = user123
  .collection('posts')          // Sub-collection posts trong user123
  .doc('post456')               // Document post có ID = post456
```

### 3.2 CRUD Operations - CẤU TRÚC CHI TIẾT:

#### A. CREATE (Tạo dữ liệu mới):
```dart
// Cách 1: Tạo document với ID tự động
static Future<String?> createPost(Map<String, dynamic> postData) async {
  try {
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('posts')
        .add(postData); // add() tự tạo ID ngẫu nhiên
    
    return docRef.id; // Trả về ID được tạo
  } catch (e) {
    print('Lỗi tạo post: $e');
    return null;
  }
}

// Cách 2: Tạo document với ID tự định
static Future<bool> createUserProfile(String userId, Map<String, dynamic> userData) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId) // Sử dụng ID có sẵn
        .set(userData); // set() để tạo hoặc ghi đè
    
    return true;
  } catch (e) {
    print('Lỗi tạo user profile: $e');
    return false;
  }
}
```

#### B. READ (Đọc dữ liệu):
```dart
// Đọc 1 document cụ thể (one-time)
static Future<Map<String, dynamic>?> getUserData(String userId) async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      print('Document không tồn tại');
      return null;
    }
  } catch (e) {
    print('Lỗi đọc user data: $e');
    return null;
  }
}

// Đọc nhiều documents (query)
static Future<List<Map<String, dynamic>>> getAllPosts() async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true) // Sắp xếp mới nhất trước
        .limit(20) // Giới hạn 20 posts
        .get();
    
    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>
    }).toList();
  } catch (e) {
    print('Lỗi lấy posts: $e');
    return [];
  }
}

// Đọc với điều kiện where
static Future<List<Map<String, dynamic>>> getPostsByUser(String userId) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: userId) // Điều kiện lọc
        .orderBy('createdAt', descending: true)
        .get();
    
    return querySnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>
    }).toList();
  } catch (e) {
    print('Lỗi lấy posts của user: $e');
    return [];
  }
}
```

#### C. UPDATE (Cập nhật dữ liệu):
```dart
// Cập nhật một số field cụ thể
static Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(), // Tự động cập nhật thời gian
    });
    
    return true;
  } catch (e) {
    print('Lỗi cập nhật profile: $e');
    return false;
  }
}

// Cập nhật với increment (tăng/giảm số)
static Future<bool> incrementLikes(String postId) async {
  try {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({
      'likes': FieldValue.increment(1), // Tăng likes lên 1
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return true;
  } catch (e) {
    print('Lỗi increment likes: $e');
    return false;
  }
}

// Cập nhật array
static Future<bool> addLikeToPost(String postId, String userId) async {
  try {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({
      'likedBy': FieldValue.arrayUnion([userId]), // Thêm vào array
      'likes': FieldValue.increment(1),
    });
    
    return true;
  } catch (e) {
    print('Lỗi add like: $e');
    return false;
  }
}

// Xóa khỏi array
static Future<bool> removeLikeFromPost(String postId, String userId) async {
  try {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({
      'likedBy': FieldValue.arrayRemove([userId]), // Xóa khỏi array
      'likes': FieldValue.increment(-1),
    });
    
    return true;
  } catch (e) {
    print('Lỗi remove like: $e');
    return false;
  }
}
```

#### D. DELETE (Xóa dữ liệu):
```dart
// Xóa document
static Future<bool> deletePost(String postId) async {
  try {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .delete();
    
    return true;
  } catch (e) {
    print('Lỗi xóa post: $e');
    return false;
  }
}
```

### 3.3 REALTIME LISTENERS (Lắng nghe thay đổi):
```dart
// Lắng nghe 1 document
static Stream<DocumentSnapshot> getUserStream(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots();
}

// Lắng nghe collection
static Stream<QuerySnapshot> getPostsStream() {
  return FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();
}

// Sử dụng trong Widget:
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('posts')
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Lỗi: ${snapshot.error}');
    }
    
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Text('Không có dữ liệu');
    }
    
    List<QueryDocumentSnapshot> posts = snapshot.data!.docs;
    
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> postData = posts[index].data() as Map<String, dynamic>;
        
        return ListTile(
          title: Text(postData['content'] ?? ''),
          subtitle: Text(postData['authorId'] ?? ''),
        );
      },
    );
  },
)
```

## PHẦN 4: CÚ PHÁP FIREBASE STORAGE

### 4.1 Upload file:
```dart
static Future<String?> uploadImage(File imageFile, String folderPath) async {
  try {
    // Tạo tên file unique
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // Tạo reference đến vị trí lưu file
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child(folderPath)
        .child(fileName);
    
    // Upload file
    UploadTask uploadTask = storageRef.putFile(imageFile);
    
    // Đợi upload hoàn thành
    TaskSnapshot snapshot = await uploadTask;
    
    // Lấy URL download
    String downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  } catch (e) {
    print('Lỗi upload image: $e');
    return null;
  }
}

// Upload với metadata
static Future<String?> uploadImageWithMetadata(File imageFile) async {
  try {
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('posts')
        .child(fileName);
    
    // Thiết lập metadata
    SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'uploadTime': DateTime.now().toString(),
      },
    );
    
    UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
    TaskSnapshot snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  } catch (e) {
    print('Lỗi upload: $e');
    return null;
  }
}
```

### 4.2 Download và delete file:
```dart
// Xóa file
static Future<bool> deleteImage(String imageUrl) async {
  try {
    Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
    await ref.delete();
    return true;
  } catch (e) {
    print('Lỗi xóa image: $e');
    return false;
  }
}
```

## PHẦN 5: TRANSACTION VÀ BATCH OPERATIONS

### 5.1 Transaction (Đảm bảo tính nhất quán):
```dart
static Future<bool> transferFollower(String fromUserId, String toUserId) async {
  try {
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Đọc documents cần thiết
      DocumentReference fromUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserId);
      DocumentReference toUserRef = FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId);
      
      DocumentSnapshot fromUserDoc = await transaction.get(fromUserRef);
      DocumentSnapshot toUserDoc = await transaction.get(toUserRef);
      
      if (!fromUserDoc.exists || !toUserDoc.exists) {
        throw Exception('User không tồn tại');
      }
      
      // Tính toán dữ liệu mới
      int fromUserFollowing = fromUserDoc.get('following') ?? 0;
      int toUserFollowers = toUserDoc.get('followers') ?? 0;
      
      // Cập nhật cả 2 documents trong cùng 1 transaction
      transaction.update(fromUserRef, {
        'following': fromUserFollowing + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      transaction.update(toUserRef, {
        'followers': toUserFollowers + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    });
  } catch (e) {
    print('Lỗi transaction: $e');
    return false;
  }
}
```

### 5.2 Batch Operations (Thao tác hàng loạt):
```dart
static Future<bool> createMultiplePosts(List<Map<String, dynamic>> postsData) async {
  try {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    for (Map<String, dynamic> postData in postsData) {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(); // Tạo ID tự động
      
      batch.set(postRef, {
        ...postData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    // Commit tất cả operations cùng lúc
    await batch.commit();
    return true;
  } catch (e) {
    print('Lỗi batch operation: $e');
    return false;
  }
}
```

## PHẦN 6: ERROR HANDLING PATTERNS

### 6.1 Cấu trúc xử lý lỗi chuẩn:
```dart
static Future<T?> safeFirebaseOperation<T>(
  Future<T> Function() operation,
  String operationName,
) async {
  try {
    return await operation();
  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error in $operationName: ${e.code} - ${e.message}');
    // Xử lý cụ thể cho từng loại lỗi auth
    return null;
  } on FirebaseException catch (e) {
    print('Firebase Error in $operationName: ${e.code} - ${e.message}');
    // Xử lý cụ thể cho từng loại lỗi Firebase
    return null;
  } catch (e) {
    print('Unexpected error in $operationName: $e');
    return null;
  }
}

// Sử dụng:
String? imageUrl = await safeFirebaseOperation(
  () => uploadImage(imageFile, 'posts'),
  'uploadImage',
);
```

## PHẦN 7: CÚ PHÁP KẾT HOP UI VỚI FIREBASE

### 7.1 FutureBuilder pattern:
```dart
FutureBuilder<Map<String, dynamic>?>(
  future: getUserData(userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Lỗi: ${snapshot.error}');
    }
    
    if (!snapshot.hasData) {
      return Text('Không có dữ liệu');
    }
    
    Map<String, dynamic> userData = snapshot.data!;
    return Text('Xin chào ${userData['displayName']}');
  },
)
```

### 7.2 StreamBuilder pattern:
```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Lỗi: ${snapshot.error}');
    }
    
    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Text('User không tồn tại');
    }
    
    Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
    
    return Column(
      children: [
        Text('Tên: ${userData['displayName']}'),
        Text('Email: ${userData['email']}'),
        Text('Followers: ${userData['followers']}'),
      ],
    );
  },
)
```

## PHẦN 8: CÚ PHÁP VALIDATION VÀ HELPER FUNCTIONS

### 8.1 Validation functions:
```dart
class FirebaseValidator {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  static bool isValidDisplayName(String name) {
    return name.trim().isNotEmpty && name.length <= 50;
  }
  
  static String? validatePostContent(String content, List<String> images) {
    if (content.trim().isEmpty && images.isEmpty) {
      return 'Post phải có nội dung hoặc hình ảnh';
    }
    
    if (content.length > 1000) {
      return 'Nội dung không được quá 1000 ký tự';
    }
    
    if (images.length > 5) {
      return 'Không được upload quá 5 ảnh';
    }
    
    return null; // Không có lỗi
  }
}
```

### 8.2 Helper functions:
```dart
class FirebaseHelper {
  // Chuyển đổi Timestamp thành DateTime
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }
  
  // Format thời gian hiển thị
  static String formatTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
  
  // Tạo ID unique
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
```

---

**KẾT LUẬN**: 

Đây là toàn bộ cú pháp Firebase cần thiết cho một Social Media app. Các điểm quan trọng:

1. **Luôn sử dụng try-catch** để xử lý lỗi
2. **Dùng static methods** cho các operations Firebase
3. **Async/await** cho operations bất đồng bộ  
4. **Stream cho realtime**, Future cho one-time operations
5. **Validation** trước khi gửi dữ liệu lên Firebase
6. **Transaction** cho operations cần đảm bảo consistency

Hãy copy từng đoạn code này vào project và thử nghiệm để hiểu cách hoạt động!
