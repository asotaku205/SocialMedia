// File: lib/services/comment_service.dart
// Service để xử lý tất cả logic liên quan đến comments

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import './auth_service.dart';

class CommentService {
  // Khởi tạo instance của Firestore
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. CREATE (TẠO COMMENT MỚI) ---
  /// Hàm tạo một comment mới cho bài viết
  /// [postId] - ID của bài viết cần comment
  /// [content] - Nội dung comment
  /// Trả về success nếu thành công, lỗi nếu thất bại
  static Future<String> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      // Lấy thông tin người dùng hiện tại
      UserModel? currentUser = await AuthService.getUser();
      if (currentUser == null) {
        return 'Người dùng chưa đăng nhập';
      }

      // Kiểm tra bài viết có tồn tại không
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        return 'Bài viết không tồn tại';
      }

      // Tạo comment model mới
      CommentModel newComment = CommentModel(
        id: '', // Firestore sẽ tự tạo ID
        postId: postId,
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        authorAvatar: currentUser.photoURL,
        content: content,
        createdAt: DateTime.now(),
      );

      // Thêm comment vào collection comments
      await _firestore.collection('comments').add(newComment.toMap());

      // Tăng số lượng comments trong bài viết
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'success';
    } catch (e) {
      print('Lỗi tạo comment: $e');
      return 'Đã có lỗi xảy ra khi tạo comment: $e';
    }
  }

  // --- 2. READ (ĐỌC COMMENTS) ---
  /// Lấy danh sách comments của một bài viết theo thời gian thực
  /// [postId] - ID của bài viết
  /// Trả về Stream để theo dõi thay đổi real-time
  static Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true) // Comment mới nhất lên đầu
        .snapshots()
        .handleError((error) {
          print('Lỗi lấy comments stream: $error');
          return <QuerySnapshot>[];
        })
        .map((snapshot) {
      List<CommentModel> comments = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data();
          CommentModel comment = CommentModel.fromMap(data, doc.id);
          comments.add(comment);
        } catch (e) {
          print('Lỗi parse comment: $e');
        }
      }

      return comments;
    });
  }

  /// Lấy danh sách comments một lần (không real-time)
  /// [postId] - ID của bài viết
  /// [limit] - Số lượng comments tối đa
  static Future<List<CommentModel>> getComments({
    required String postId,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      List<CommentModel> comments = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          CommentModel comment = CommentModel.fromMap(data, doc.id);
          comments.add(comment);
        } catch (e) {
          print('Lỗi parse comment: $e');
        }
      }

      return comments;
    } catch (e) {
      print('Lỗi lấy comments: $e');
      return [];
    }
  }

  // --- 3. DELETE (XÓA COMMENT) ---
  /// Xóa một comment
  /// [commentId] - ID của comment cần xóa
  /// [postId] - ID của bài viết chứa comment
  /// Chỉ tác giả comment hoặc tác giả bài viết mới có thể xóa
  static Future<String> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    try {
      // Lấy thông tin người dùng hiện tại
      String? currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        return 'Người dùng chưa đăng nhập';
      }

      // Lấy thông tin comment để kiểm tra quyền
      DocumentSnapshot commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return 'Comment không tồn tại';
      }

      Map<String, dynamic> commentData = commentDoc.data() as Map<String, dynamic>;
      String commentAuthorId = commentData['authorId'] ?? '';

      // Lấy thông tin bài viết để kiểm tra quyền
      DocumentSnapshot postDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        return 'Bài viết không tồn tại';
      }

      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
      String postAuthorId = postData['authorId'] ?? '';

      // Kiểm tra quyền: chỉ tác giả comment hoặc tác giả bài viết mới được xóa
      if (currentUserId != commentAuthorId && currentUserId != postAuthorId) {
        return 'Bạn không có quyền xóa comment này';
      }

      // Xóa comment
      await _firestore.collection('comments').doc(commentId).delete();

      // Giảm số lượng comments trong bài viết
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'success';
    } catch (e) {
      print('Lỗi xóa comment: $e');
      return 'Đã có lỗi xảy ra khi xóa comment: $e';
    }
  }

  // --- 4. UPDATE (CẬP NHẬT COMMENT) ---
  /// Cập nhật nội dung comment
  /// [commentId] - ID của comment cần cập nhật
  /// [newContent] - Nội dung mới
  /// Chỉ tác giả comment mới có thể sửa
  static Future<String> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    try {
      // Lấy thông tin người dùng hiện tại
      String? currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        return 'Người dùng chưa đăng nhập';
      }

      // Lấy thông tin comment để kiểm tra quyền
      DocumentSnapshot commentDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return 'Comment không tồn tại';
      }

      Map<String, dynamic> commentData = commentDoc.data() as Map<String, dynamic>;
      String commentAuthorId = commentData['authorId'] ?? '';

      // Kiểm tra quyền: chỉ tác giả comment mới được sửa
      if (currentUserId != commentAuthorId) {
        return 'Bạn không có quyền sửa comment này';
      }

      // Cập nhật comment
      await _firestore.collection('comments').doc(commentId).update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'success';
    } catch (e) {
      print('Lỗi cập nhật comment: $e');
      return 'Đã có lỗi xảy ra khi cập nhật comment: $e';
    }
  }

  // --- 5. UTILITY METHODS ---
  /// Đếm số lượng comments của một bài viết
  /// [postId] - ID của bài viết
  static Future<int> getCommentsCount(String postId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Lỗi đếm comments: $e');
      return 0;
    }
  }

  /// Lấy comments của một user cụ thể
  /// [userId] - ID của user
  static Future<List<CommentModel>> getUserComments(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('comments')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<CommentModel> comments = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          CommentModel comment = CommentModel.fromMap(data, doc.id);
          comments.add(comment);
        } catch (e) {
          print('Lỗi parse user comment: $e');
        }
      }

      return comments;
    } catch (e) {
      print('Lỗi lấy user comments: $e');
      return [];
    }
  }
}