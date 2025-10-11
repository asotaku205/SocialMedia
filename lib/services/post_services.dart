import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Cần cho việc upload file
import 'package:image_picker/image_picker.dart';

import '../models/post_model.dart'; // Import model bạn vừa tạo
import '../models/user_model.dart'; // Import UserModel để lấy thông tin tác giả
import '../models/comment_model.dart'; // Import CommentModel
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
    XFile? imageFile, // Nhận vào một XFile ảnh (có thể null)
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
        id: '',
        // Firestore sẽ tự tạo ID
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

      // Tự động tăng postCount lên 1
      await AuthService.incrementPostCount(currentUser.uid);

      return 'success';
    } catch (e) {
      print('Lỗi tạo post: $e');
      return 'Đã có lỗi xảy ra khi tạo bài viết.';
    }
  }

  // --- 2. READ (ĐỌC DỮ LIỆU) ---
  /// Lấy danh sách tất cả bài viết theo thời gian thực (real-time).
  /// Trả về một Stream, tự động cập nhật UI khi có bài viết mới.
  static Stream<List<PostModel>> getFriendsPostsStream() async* {
    try {
      final String? currentUserId = AuthService.currentUser?.uid;
      if (currentUserId == null) {
        print('No current user ID');
        yield [];
        return;
      }

      // Lấy bạn bè từ trường friends trong user document thay vì subcollection
      DocumentSnapshot userDoc;
      try {
        userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();
      } catch (e) {
        print('Error fetching user document: $e');
        yield [];
        return;
      }

      List<String> friendIds = [];
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        // Lấy danh sách friends từ trường friends array
        List<dynamic> friends = userData['friends'] ?? [];
        friendIds = friends.cast<String>();
      }

      // Thêm chính mình vào danh sách
      friendIds.add(currentUserId);

      // Loại bỏ duplicates
      friendIds = friendIds.toSet().toList();

      print('Friend IDs count: ${friendIds.length}');
      print('Friend IDs: $friendIds');

      if (friendIds.isEmpty) {
        yield [];
        return;
      }

      // Delay để tránh overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));

      // Sử dụng approach mới để tránh composite index
      yield* _getPostsWithoutCompositeIndex(friendIds);
    } catch (e) {
      print('Error in getFriendsPostsStream: $e');
      yield [];
    }
  }

  // Method mới để lấy posts mà không cần composite index
  static Stream<List<PostModel>> _getPostsWithoutCompositeIndex(List<String> friendIds) async* {
    try {
      // Lấy tất cả posts trước, sau đó filter và sort trong code
      yield* _firestore
          .collection('posts')
          .snapshots()
          .handleError((error) {
            print('Firestore posts stream error: $error');
            return <QuerySnapshot>[];
          })
          .map((snapshot) {
        List<PostModel> allPosts = [];

        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data();
            data['id'] = doc.id;

            // Chỉ lấy posts từ bạn bè
            String authorId = data['authorId'] ?? '';
            if (friendIds.contains(authorId)) {
              PostModel post = PostModel.fromMap(data, doc.id);
              allPosts.add(post);
            }
          } catch (e) {
            print('Error parsing post: $e');
          }
        }

        // Sort theo thời gian tạo (mới nhất lên đầu)
        allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return allPosts;
      });
    } catch (e) {
      print('Error in _getPostsWithoutCompositeIndex: $e');
      yield [];
    }
  }

  // Fallback method để get all posts (cho debug)
  static Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection('posts')
        .snapshots()
        .handleError((error) {
          print('Firestore getPostsStream error: $error');
          return <QuerySnapshot>[];
        })
        .map((snapshot) {
      List<PostModel> posts = [];

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          PostModel post = PostModel.fromMap(data, doc.id);
          posts.add(post);
        } catch (e) {
          print('Error parsing post in getPostsStream: $e');
        }
      }

      // Sort theo thời gian tạo
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return posts;
    });
  }

  // Method để kiểm tra và debug friendship data
  static Future<void> debugFriendshipData(String userId) async {
    try {
      print('=== DEBUG FRIENDSHIP DATA ===');

      // Kiểm tra user document
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<dynamic> friends = userData['friends'] ?? [];
        print('Friends in user document: $friends');
        print('Friends count: ${friends.length}');
      } else {
        print('User document does not exist!');
      }

      // Kiểm tra friends subcollection
      QuerySnapshot friendsSubcollection = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      print('Friends in subcollection: ${friendsSubcollection.docs.length}');
      for (var doc in friendsSubcollection.docs) {
        print('Friend subcollection doc: ${doc.id}');
      }

      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in debugFriendshipData: $e');
    }
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
      // Lấy thông tin bài viết trước khi xóa để biết authorId
      DocumentSnapshot postDoc = await _firestore.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        return 'Bài viết không tồn tại';
      }

      // Lấy authorId từ document
      String authorId = postDoc.get('authorId') ?? '';

      // Xóa bài viết
      await _firestore.collection('posts').doc(postId).delete();

      // Tự động giảm postCount xuống 1 nếu có authorId
      if (authorId.isNotEmpty) {
        await AuthService.decrementPostCount(authorId);
      }

      return 'success';
    } catch (e) {
      return 'Lỗi khi xóa bài viết: $e';
    }
  }

  // --- HÀM HỖ TRỢ UPLOAD ẢNH ---
  /// Hàm riêng tư để upload ảnh lên Firebase Storage.
  static Future<String?> _uploadImage(XFile imageFile, String folderPath) async {
    try {
      // Tạo một tên file độc nhất dựa trên thời gian
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('$folderPath/$fileName');

      // Đọc file thành bytes để tương thích với web
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Bắt đầu quá trình upload với bytes
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;

      // Lấy URL của ảnh sau khi upload thành công
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Lỗi upload ảnh: $e');
      return null;
    }
  }

  // --- COMMENTS METHODS ---
  /// Cập nhật số lượng comments của một post
  /// [postId] - ID của post cần cập nhật
  /// [increment] - Số lượng cần tăng/giảm (dương để tăng, âm để giảm)
  static Future<String> updateCommentsCount(String postId, int increment) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(increment),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'success';
    } catch (e) {
      print('Lỗi cập nhật comments count: $e');
      return 'Lỗi cập nhật số lượng comments: $e';
    }
  }

  /// Lấy số lượng comments thực tế từ Firestore để đồng bộ
  /// [postId] - ID của post
  static Future<int> getActualCommentsCount(String postId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Lỗi lấy actual comments count: $e');
      return 0;
    }
  }

  /// Đồng bộ số lượng comments cho một post cụ thể
  /// Hữu ích khi số lượng comments bị sai lệch
  /// [postId] - ID của post cần đồng bộ
  static Future<String> syncCommentsCount(String postId) async {
    try {
      int actualCount = await getActualCommentsCount(postId);
      
      await _firestore.collection('posts').doc(postId).update({
        'comments': actualCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return 'success';
    } catch (e) {
      print('Lỗi sync comments count: $e');
      return 'Lỗi đồng bộ số lượng comments: $e';
    }
  }

  /// Lấy danh sách comments của một post (phương thức này trong PostService để dự phòng)
  /// Tuy nhiên nên dùng CommentService.getCommentsStream() cho real-time
  static Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .get();

      List<CommentModel> comments = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          CommentModel comment = CommentModel.fromMap(data, doc.id);
          comments.add(comment);
        } catch (e) {
          print('Lỗi parse comment trong PostService: $e');
        }
      }

      return comments;
    } catch (e) {
      print('Lỗi lấy post comments: $e');
      return [];
    }
  }
}
