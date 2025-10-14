// Import các package cần thiết
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'encryption_service.dart';

// Class AuthService - quản lý tất cả logic xác thực người dùng
class AuthService {
  // Khởi tạo Firebase Auth instance - singleton pattern
  // Static final đảm bảo chỉ có 1 instance duy nhất trong toàn app
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Khởi tạo Firestore instance - để tương tác với database
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter để lấy user hiện tại đang đăng nhập
  // Trả về User object hoặc null nếu chưa đăng nhập
  static User? get currentUser => _auth.currentUser;

  // Stream để lắng nghe thay đổi authentication state
  // Tự động emit events khi user đăng nhập/đăng xuất
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<String> forgotPassword({required String email}) async {
    try {
      if (email.isEmpty) {
        return 'Please enter your email';
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email format';
      } else {
        return 'An unknown error occurred: ${e.message}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  static Future<String> signUp({
    required String email,
    required String password,
    required String userName,
    required String passwordConfirm,
  }) async {
    try {
      // Kiểm tra tất cả trường bắt buộc đã được nhập
      if (email.isEmpty || password.isEmpty || userName.isEmpty || passwordConfirm.isEmpty) {
        return 'Please fill in all fields';
      }

      // Kiểm tra mật khẩu và xác nhận mật khẩu có khớp không
      if (password != passwordConfirm) {
        return 'Password and Confirm Password do not match';
      }

      // Kiểm tra độ dài mật khẩu tối thiểu
      if (password.length < 6) {
        return 'Password must be at least 6 characters long';
      }

      // Validate email format bằng Regular Expression
      // Pattern: có ít nhất 1 ký tự trước @, có @, có ít nhất 1 ký tự sau @, có dấu chấm, có domain
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
        return 'Invalid email format';
      }

      // Validate username format: chỉ cho phép chữ cái, số và dấu gạch dưới
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(userName.trim())) {
        return 'Username can only contain letters, numbers, and underscores without spaces';
      }

      // Query Firestore để tìm user có cùng userName
      final userNameQuery = await _firestore
          .collection('users')
          .where('userName', isEqualTo: userName.trim())
          .get();

      // Nếu tìm thấy documents có userName này -> đã tồn tại
      if (userNameQuery.docs.isNotEmpty) {
        return 'Username already exists';
      }

      // createUserWithEmailAndPassword: tạo account trong Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim()
      );

      // Lấy User object từ credential
      User? user = userCredential.user;
      if (user == null) {
        return 'User creation failed';
      }

      // Tạo UserModel với thông tin user và default values
      UserModel newUser = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: userName.trim(),
        userName: userName.trim(),
        bio: '',
        photoURL: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Lưu UserModel vào Firestore collection 'users'
      // Document ID = user.uid để dễ dàng map với Firebase Auth
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // Khởi tạo keys mã hóa cho user mới
      try {
        await EncryptionService.initializeKeys();
      } catch (e) {
        print('Warning: Could not initialize encryption keys: $e');
      }

      return 'success';
    } on FirebaseAuthException catch (e) {
      // Xử lý các lỗi cụ thể từ Firebase Auth
      if (e.code == 'email-already-in-use') {
        return 'Email is already in use';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak';
      } else {
        return 'An unknown error occurred: ${e.message}';
      }
    } catch (e) {
      // Xử lý các lỗi khác (network, Firestore, etc.)
      return 'An unexpected error occurred: $e';
    }
  }

  // Xác thực user và trả về UserModel nếu thành công
  // Returns: UserModel object hoặc null nếu thất bại
  static Future<UserModel?> signIn({
    required String email,
    required String password
  }) async {
    try {
      // Kiểm tra email và password không được rỗng
      if (email.isEmpty || password.isEmpty) {
        print('Email and password cannot be empty');
        return null;
      }

      // signInWithEmailAndPassword: xác thực user credentials
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim()
      );

      // Lấy User object từ credential
      User? user = userCredential.user;
      if (user == null) {
        print('Sign in failed - no user returned');
        return null;
      }

      // Lấy document user từ Firestore bằng UID
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      // Kiểm tra document có tồn tại không
      if (userDoc.exists) {
        // Khởi tạo keys mã hóa nếu chưa có
        try {
          await EncryptionService.initializeKeys();
        } catch (e) {
          print('Warning: Could not initialize encryption keys: $e');
        }

        // Convert Firestore data thành UserModel
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id
        );
      } else {
        print('User document does not exist in Firestore');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      // Xử lý các lỗi Firebase Auth cụ thể
      if (e.code == 'user-not-found') {
        print('No user found for that email');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided');
      } else if (e.code == 'invalid-email') {
        print('Invalid email format');
      } else {
        print('Firebase Auth Error: ${e.message}');
      }
      return null;
    } catch (e) {
      // Xử lý các lỗi khác
      print('Unexpected error during sign in: $e');
      return null;
    }
  }


  static Future<void> logout() async {
    try {
      // KHÔNG xóa encryption keys khi logout thông thường
      // Khóa sẽ được giữ lại để user có thể xem tin nhắn cũ khi đăng nhập lại
      // Chỉ xóa khóa khi: reset password, xóa thiết bị tin cậy, etc.
      
      // signOut(): xóa authentication state, user sẽ thành null
      await _auth.signOut();

      print('User logged out successfully (encryption keys preserved)');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  static Future<UserModel?> getUser() async {
    try {
      // Lấy user hiện tại từ Firebase Auth
      User? user = _auth.currentUser;
      if (user == null) {
        print('No user is currently signed in');
        return null;
      }

      // Lấy document user từ Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      // Kiểm tra document có tồn tại
      if (userDoc.exists) {
        // Convert Firestore data sang UserModel
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id
        );
      } else {
        print('User document not found in Firestore');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }


  static Future<String> updateProfile({
    String? displayName,
    String? bio,
    String? photoURL
  }) async {
    try {
      // Kiểm tra user đã đăng nhập chưa
      User? user = _auth.currentUser;
      if (user == null) {
        return 'No user is currently signed in';
      }

      // Tạo reference đến document user trong Firestore
      DocumentReference userRef = _firestore.collection('users').doc(user.uid);

      // Tạo Map chứa data cần update
      Map<String, dynamic> updateData = {};

      // Chỉ thêm field vào updateData nếu có giá trị mới
      if (displayName != null && displayName.isNotEmpty) {
        updateData['displayName'] = displayName.trim();
      }
      if (bio != null) {
        // Bio có thể rỗng (user muốn xóa bio)
        updateData['bio'] = bio.trim();
      }
      if (photoURL != null && photoURL.isNotEmpty) {
        updateData['photoURL'] = photoURL.trim();
        print('Updating photoURL: $photoURL'); // Debug log
      }

      // Nếu có ít nhất 1 field để update
      if (updateData.isNotEmpty) {
        // Thêm timestamp update tự động từ server
        updateData['updatedAt'] = FieldValue.serverTimestamp();

        // Thực hiện update document trong Firestore
        await userRef.update(updateData);
        print('Profile updated successfully with data: $updateData'); // Debug log
      }

      return 'success';
    } catch (e) {
      // Xử lý lỗi và trả về message
      print('Error updating profile: $e'); // Debug log
      return 'Failed to update profile: $e';
    }
  }

  // Method để update số lượng bài post
  static Future<String> updatePostCount(String userId, int newPostCount) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'postCount': newPostCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'success';
    } catch (e) {
      print('Error updating post count: $e');
      return 'Failed to update post count: $e';
    }
  }

  // Method để tăng số bài post lên 1
  static Future<String> incrementPostCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'postCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'success';
    } catch (e) {
      print('Error incrementing post count: $e');
      return 'Failed to increment post count: $e';
    }
  }

  // Method để giảm số bài post xuống 1
  static Future<String> decrementPostCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'postCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'success';
    } catch (e) {
      print('Error decrementing post count: $e');
      return 'Failed to decrement post count: $e';
    }
  }

  // Method để đồng bộ postCount với số bài viết thực tế
  static Future<String> syncPostCount(String userId) async {
    try {
      // Đếm số bài viết thực tế của user
      final postsQuery = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .get();

      final actualPostCount = postsQuery.docs.length;

      // Cập nhật postCount trong user document
      await _firestore.collection('users').doc(userId).update({
        'postCount': actualPostCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Synced post count for user $userId: $actualPostCount posts');
      return 'success';
    } catch (e) {
      print('Error syncing post count: $e');
      return 'Failed to sync post count: $e';
    }
  }
}
