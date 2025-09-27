import 'dart:io'; // Cần để làm việc với file ảnh
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Cần cho việc upload file
import '../models/post_model.dart'; // Import model bạn vừa tạo
import '../models/user_model.dart'; // Import UserModel để lấy thông tin tác giả
import './auth_service.dart'; // Import AuthService để lấy thông tin user

class PostService {
  // Khởi tạo các instance của Firestore và Storage
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. CREATE (TẠO MỚI) ---
  /// Hàm tạo một bài viết mới trên Firestore.
  /// Nhận vào một object PostModel và trả về true nếu thành công.
  static Future<String> createPost({
    required String content,
    File? imageFile, // Nhận vào một File ảnh (có thể null)
  }) async {
    try {
      // Lấy thông tin người dùng hiện tại
      UserModel? currentUser = await AuthService.getUser();
      if (currentUser == null) {
        return 'Người dùng chưa đăng nhập';
      }

      String imageUrl = '';
      // Nếu có ảnh, upload lên Firebase Storage trước
      if (imageFile != null) {
        String? uploadedUrl = await _uploadImage(imageFile, 'posts_images');
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // Tạo một object PostModel mới
      PostModel newPost = PostModel(
        id: '', // Firestore sẽ tự tạo ID
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        authorAvatar: currentUser.photoURL,
        content: content,
        imageUrls: imageUrl.isNotEmpty ? [imageUrl] : [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Thêm bài viết vào collection 'posts'
      await _firestore.collection('posts').add(newPost.toMap());
      return 'success';
    } catch (e) {
      print('Lỗi tạo post: $e');
      return 'Đã có lỗi xảy ra khi tạo bài viết.';
    }
  }

  // --- 2. READ (ĐỌC DỮ LIỆU) ---
  /// Lấy danh sách tất cả bài viết theo thời gian thực (real-time).
  /// Trả về một Stream, tự động cập nhật UI khi có bài viết mới.
  static Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true) // Sắp xếp bài mới nhất lên đầu
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // --- 3. UPDATE (CẬP NHẬT) ---
  /// Hàm để like hoặc unlike một bài viết.
  /// Dùng Transaction để đảm bảo an toàn dữ liệu khi nhiều người cùng like.
  static Future<String> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);

        if (!snapshot.exists) {
          throw Exception("Bài viết không tồn tại!");
        }

        List<String> likedBy = List<String>.from(snapshot['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          // Nếu đã like -> Unlike
          transaction.update(postRef, {
            'likedBy': FieldValue.arrayRemove([userId]),
            'likes': FieldValue.increment(-1),
          });
        } else {
          // Nếu chưa like -> Like
          transaction.update(postRef, {
            'likedBy': FieldValue.arrayUnion([userId]),
            'likes': FieldValue.increment(1),
          });
        }
      });
      return 'success';
    } catch (e) {
      return 'Lỗi: $e';
    }
  }

  // --- 4. DELETE (XÓA) ---
  /// Hàm xóa một bài viết.
  static Future<String> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return 'success';
    } catch (e) {
      return 'Lỗi khi xóa bài viết: $e';
    }
  }

  // --- HÀM HỖ TRỢ UPLOAD ẢNH ---
  /// Hàm riêng tư để upload ảnh lên Firebase Storage.
  static Future<String?> _uploadImage(File imageFile, String folderPath) async {
    try {
      // Tạo một tên file độc nhất dựa trên thời gian
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('$folderPath/$fileName');

      // Bắt đầu quá trình upload
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL của ảnh sau khi upload thành công
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Lỗi upload ảnh: $e');
      return null;
    }
  }
}
