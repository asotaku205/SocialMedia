# HƯỚNG DẪN XÂY DỰNG SOCIAL MEDIA APP TỪNG BƯỚC

## 🎯 MỤC TIÊU
Xây dựng một Social Media app hoàn chỉnh với Firebase backend, bao gồm:
- Authentication (đăng ký, đăng nhập)
- Profile management
- Tạo và hiển thị posts
- Like/Comment system
- Real-time chat

## 📋 CHUẨN BỊ
- ✅ Flutter đã cài đặt
- ✅ Firebase project đã tạo
- ✅ Biết cách xây dựng UI Flutter cơ bản

---

## BƯỚC 1: SETUP FIREBASE (30 phút)

### 1.1 Cài đặt Firebase packages
Mở `pubspec.yaml` và thêm dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase packages
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.6.0
  
  # UI và utility packages
  image_picker: ^1.0.4
  google_fonts: ^6.1.0
  provider: ^6.1.1
  
  cupertino_icons: ^1.0.2
```

Chạy lệnh:
```bash
flutter pub get
```

### 1.2 Khởi tạo Firebase trong main.dart
Thay thế nội dung `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Temporary wrapper - sẽ implement sau
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Social Media App')),
      body: Center(
        child: Text('Firebase Setup Complete!'),
      ),
    );
  }
}
```

**✅ Test:** Chạy app và đảm bảo không có lỗi.

---

## BƯỚC 2: TẠO USER MODEL (15 phút)

### 2.1 Tạo file `lib/models/user_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String bio;
  final int followers;
  final int following;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL = '',
    this.bio = '',
    this.followers = 0,
    this.following = 0,
    this.createdAt,
  });

  // Chuyển từ Firebase Document sang UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      bio: map['bio'] ?? '',
      followers: map['followers'] ?? 0,
      following: map['following'] ?? 0,
      createdAt: map['createdAt']?.toDate(),
    );
  }

  // Chuyển từ UserModel sang Map để lưu Firebase
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'followers': followers,
      'following': following,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Helper methods
  String get firstLetter => displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
  bool get hasProfileImage => photoURL.isNotEmpty;
}
```

---

## BƯỚC 3: TẠO AUTH SERVICE (30 phút)

### 3.1 Tạo file `lib/services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy user hiện tại
  static User? get currentUser => _auth.currentUser;

  // Stream để lắng nghe thay đổi auth state
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký tài khoản mới
  static Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Bước 1: Tạo tài khoản Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Bước 2: Tạo UserModel
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      // Bước 3: Lưu user info vào Firestore
      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      print('Lỗi đăng ký: ${e.message}');
      return null;
    } catch (e) {
      print('Lỗi không xác định: $e');
      return null;
    }
  }

  // Đăng nhập
  static Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy thông tin user từ Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Lỗi đăng nhập: ${e.message}');
      return null;
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy thông tin user từ Firestore
  static Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
      }
      return null;
    } catch (e) {
      print('Lỗi lấy user data: $e');
      return null;
    }
  }
}
```

---

## BƯỚC 4: TẠO LOGIN SCREEN (45 phút)

### 4.1 Tạo file `lib/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    UserModel? user = await AuthService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Đăng nhập thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo hoặc title
            Text(
              'Social Media App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 40),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 16),

            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 16),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Đăng nhập', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 16),

            // Sign up link
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                );
              },
              child: Text('Chưa có tài khoản? Đăng ký ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 Tạo file `lib/screens/signup_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty ||
        _displayNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ thông tin';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    UserModel? user = await AuthService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      displayName: _displayNameController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Đăng ký thành công
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tạo tài khoản mới',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 40),

            // Display name field
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Tên hiển thị',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            SizedBox(height: 16),

            // Error message
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 16),

            // Sign up button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Đăng ký', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## BƯỚC 5: TẠO AUTH WRAPPER VÀ HOME SCREEN (30 phút)

### 5.1 Cập nhật `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Đã đăng nhập
        if (snapshot.hasData) {
          return HomeScreen();
        }

        // Chưa đăng nhập
        return LoginScreen();
      },
    );
  }
}
```

### 5.2 Tạo file `lib/screens/home_screen.dart` (tạm thời)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trang chủ'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              // AuthWrapper sẽ tự động chuyển về LoginScreen
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Xin chào, ${user?.email ?? "User"}!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text('Authentication hoạt động thành công!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sẽ implement tính năng posts ở bước tiếp theo')),
                );
              },
              child: Text('Tạo bài viết'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## BƯỚC 6: TEST AUTHENTICATION (15 phút)

### 6.1 Tạo thư mục screens
Tạo thư mục `lib/screens/` và di chuyển các file screen vào đó.

### 6.2 Cập nhật imports
Đảm bảo tất cả import paths đều đúng.

### 6.3 Test app
1. Chạy `flutter run`
2. Test đăng ký tài khoản mới
3. Test đăng xuất
4. Test đăng nhập với tài khoản vừa tạo
5. Kiểm tra Firebase Console để xem users đã được tạo

**✅ Checkpoint:** Authentication phải hoạt động hoàn toàn trước khi tiếp tục.

---

## BƯỚC 7: TẠO POST MODEL VÀ SERVICE (45 phút)

### 7.1 Tạo file `lib/models/post_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? id;
  final String authorId;
  final String content;
  final List<String> imageUrls;
  final List<String> likedBy;
  final int likes;
  final int comments;
  final DateTime? createdAt;

  PostModel({
    this.id,
    required this.authorId,
    required this.content,
    this.imageUrls = const [],
    this.likedBy = const [],
    this.likes = 0,
    this.comments = 0,
    this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PostModel(
      id: documentId,
      authorId: map['authorId'] ?? '',
      content: map['content'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      likedBy: List<String>.from(map['likedBy'] ?? []),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: map['createdAt']?.toDate(),
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
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  // Helper methods
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool get hasImages => imageUrls.isNotEmpty;
  
  String get timeAgo {
    if (createdAt == null) return '';
    final difference = DateTime.now().difference(createdAt!);
    
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
}
```

### 7.2 Tạo file `lib/services/post_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tạo post mới
  static Future<bool> createPost(PostModel post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
      return true;
    } catch (e) {
      print('Lỗi tạo post: $e');
      return false;
    }
  }

  // Lấy tất cả posts (Stream để realtime update)
  static Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Toggle like post
  static Future<bool> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot postSnapshot = await transaction.get(postRef);
        
        if (!postSnapshot.exists) {
          throw Exception("Post không tồn tại!");
        }
        
        PostModel post = PostModel.fromMap(
          postSnapshot.data() as Map<String, dynamic>, 
          postSnapshot.id
        );
        
        List<String> newLikedBy = List.from(post.likedBy);
        int newLikes = post.likes;
        
        if (post.isLikedBy(userId)) {
          // Unlike
          newLikedBy.remove(userId);
          newLikes--;
        } else {
          // Like
          newLikedBy.add(userId);
          newLikes++;
        }
        
        transaction.update(postRef, {
          'likedBy': newLikedBy,
          'likes': newLikes,
        });
        
        return true;
      });
    } catch (e) {
      print('Lỗi toggle like: $e');
      return false;
    }
  }

  // Xóa post (chỉ author được xóa)
  static Future<bool> deletePost(String postId, String currentUserId) async {
    try {
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();
      
      if (!postDoc.exists) return false;
      
      PostModel post = PostModel.fromMap(
        postDoc.data() as Map<String, dynamic>, 
        postDoc.id
      );
      
      // Chỉ author mới được xóa
      if (post.authorId != currentUserId) return false;
      
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      print('Lỗi xóa post: $e');
      return false;
    }
  }
}
```

---

## BƯỚC 8: TẠO CREATE POST SCREEN (30 phút)

### 8.1 Tạo file `lib/screens/create_post_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../models/post_model.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập nội dung bài viết')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    PostModel newPost = PostModel(
      authorId: AuthService.currentUser!.uid,
      content: _contentController.text.trim(),
      createdAt: DateTime.now(),
    );

    bool success = await PostService.createPost(newPost);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pop(context); // Quay về màn hình trước
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo bài viết thành công!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo bài viết thất bại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo bài viết'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Đăng',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    AuthService.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  AuthService.currentUser?.email ?? 'User',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Content input
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Bạn đang nghĩ gì?',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 18),
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## BƯỚC 9: CẬP NHẬT HOME SCREEN VỚI POSTS (45 phút)

### 9.1 Cập nhật file `lib/screens/home_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'create_post_screen.dart';
import '../widgets/post_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Media'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: PostService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có bài viết nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreatePostScreen()),
                      );
                    },
                    child: Text('Tạo bài viết đầu tiên'),
                  ),
                ],
              ),
            );
          }

          List<PostModel> posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return PostWidget(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### 9.2 Tạo file `lib/widgets/post_widget.dart`

```dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

class PostWidget extends StatefulWidget {
  final PostModel post;

  const PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  UserModel? author;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadAuthorInfo();
    _checkIfLiked();
  }

  Future<void> _loadAuthorInfo() async {
    UserModel? userData = await AuthService.getUserData(widget.post.authorId);
    if (mounted) {
      setState(() {
        author = userData;
      });
    }
  }

  void _checkIfLiked() {
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId != null) {
      setState(() {
        isLiked = widget.post.isLikedBy(currentUserId);
      });
    }
  }

  Future<void> _toggleLike() async {
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null || widget.post.id == null) return;

    // Optimistic update - cập nhật UI trước
    setState(() {
      isLiked = !isLiked;
    });

    bool success = await PostService.toggleLike(widget.post.id!, currentUserId);
    
    if (!success) {
      // Revert nếu thất bại
      setState(() {
        isLiked = !isLiked;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể like bài viết')),
      );
    }
  }

  Future<void> _deletePost() async {
    String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null || widget.post.id == null) return;

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      bool success = await PostService.deletePost(widget.post.id!, currentUserId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa bài viết')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currentUserId = AuthService.currentUser?.uid;
    bool isAuthor = currentUserId == widget.post.authorId;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                author?.firstLetter ?? 'U',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(author?.displayName ?? 'Loading...'),
            subtitle: Text(widget.post.timeAgo),
            trailing: isAuthor
                ? PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost();
                      }
                    },
                  )
                : null,
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.post.content,
              style: TextStyle(fontSize: 16),
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('${widget.post.likes}'),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.comment, color: Colors.grey),
                  onPressed: () {
                    // TODO: Implement comments
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tính năng comment sẽ được thêm sau')),
                    );
                  },
                ),
                Text('${widget.post.comments}'),
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

## BƯỚC 10: TEST VÀ DEBUG (15 phút)

### 10.1 Tạo thư mục widgets
Tạo thư mục `lib/widgets/` và đảm bảo file `post_widget.dart` ở đúng vị trí.

### 10.2 Test các tính năng
1. **Tạo post:** Test tạo bài viết mới
2. **Real-time:** Mở app trên 2 thiết bị/browser, tạo post trên 1 thiết bị và xem có xuất hiện real-time trên thiết bị khác không
3. **Like/Unlike:** Test like và unlike posts
4. **Delete post:** Test xóa post (chỉ author được xóa)
5. **Authentication:** Test đăng xuất và đăng nhập lại

---

## BƯỚC 11: THIẾT LẬP FIREBASE SECURITY RULES (20 phút)

### 11.1 Cập nhật Firestore Security Rules
Vào Firebase Console > Firestore Database > Rules và thay thế bằng:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection rules
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Posts collection rules  
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.authorId;
    }
  }
}
```

### 11.2 Test Security Rules
1. Thử truy cập app khi chưa đăng nhập
2. Thử xóa post của người khác
3. Đảm bảo chỉ có thể xem posts khi đã đăng nhập

---

## 🎉 HOÀN THÀNH BƯỚC CƠ BẢN!

Bạn đã hoàn thành một Social Media app cơ bản với:
- ✅ Authentication (đăng ký, đăng nhập, đăng xuất)
- ✅ Tạo và hiển thị posts
- ✅ Like/Unlike posts real-time
- ✅ Xóa posts (chỉ author)
- ✅ Security rules cơ bản

---

## BƯỚC TIẾP THEO (TÙY CHỌN)

### BƯỚC 12: THÊM UPLOAD HÌNH ẢNH
- Tích hợp image_picker
- Upload lên Firebase Storage
- Hiển thị images trong posts

### BƯỚC 13: PROFILE SCREEN
- Xem và edit profile
- Upload avatar
- Hiển thị posts của user

### BƯỚC 14: COMMENTS SYSTEM
- Tạo CommentModel
- Add/delete comments
- Real-time comments

### BƯỚC 15: CHAT FEATURES
- One-on-one messaging
- Real-time chat
- Message status

### BƯỚC 16: ADVANCED FEATURES
- Push notifications
- Search users
- Follow/Unfollow
- News feed algorithm

---

## 🔧 TROUBLESHOOTING

### Lỗi thường gặp:
1. **Firebase not initialized:** Đảm bảo `Firebase.initializeApp()` được gọi trong `main()`
2. **Import errors:** Kiểm tra đường dẫn import
3. **Security rules:** Đảm bảo user đã đăng nhập trước khi truy cập Firestore
4. **Real-time không hoạt động:** Kiểm tra internet connection và Firebase rules

### Debug tips:
- Sử dụng `print()` để debug
- Kiểm tra Firebase Console để xem dữ liệu
- Test từng tính năng một cách riêng biệt

---

**🎯 Mục tiêu:** Sau khi hoàn thành 11 bước này, bạn sẽ có một Social Media app hoạt động hoàn chỉnh với Firebase backend!
