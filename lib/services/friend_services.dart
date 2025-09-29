import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> SendFriendRequest(String receiverId) async {
    try {
      String? currentUser = AuthService.currentUser?.uid;
      if (currentUser == null) {
        return 'User not logged in';
      }
      String senderId = currentUser;
      if (senderId == receiverId) {
        return 'You cannot send a friend request to yourself';
      }
      //kiểm tra xem đã request chưa
      QuerySnapshot existingFriendship = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .get();
      QuerySnapshot reverseFriendship = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .get();
      if (existingFriendship.docs.isNotEmpty) {
        friendShipModel friendship = friendShipModel.fromMap(
          existingFriendship.docs.first.data() as Map<String, dynamic>,
          existingFriendship.docs.first.id,
        );
        if (friendship.status == 'pending') {
          return 'Lời mời đã được gửi trước đó';
        } else if (friendship.status == 'accepted') {
          return 'Hai bạn đã là bạn bè';
        }
      }
      if (reverseFriendship.docs.isNotEmpty) {
        friendShipModel friendship = friendShipModel.fromMap(
          reverseFriendship.docs.first.data() as Map<String, dynamic>,
          reverseFriendship.docs.first.id,
        );
        if (friendship.status == 'pending') {
          return 'Người này đã gửi lời mời kết bạn cho bạn. Vui lòng kiểm tra trong danh sách lời mời.';
        } else if (friendship.status == 'accepted') {
          return 'Hai bạn đã là bạn bè';
        }
      }
      // Tạo một lời mời kết bạn mới
      friendShipModel newRequest = friendShipModel(
        uid: '',
        senderId: senderId,
        receiverId: receiverId,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('friendships').add(newRequest.toMap());
      return 'success';
    } catch (e) {
      print('Error sending friend request: $e');
      return 'An error occurred while sending the friend request.';
    }
  }

  // Accept friend request
  static Future<String> AcceptFriendRequest(String requestId) async {
    try {
      String? currentUser = AuthService.currentUser?.uid;
      if (currentUser == null) {
        return 'User not logged in';
      }
      DocumentSnapshot friendshipDoc = await _firestore.collection('friendships').doc(requestId).get();
      if (!friendshipDoc.exists) {
        return 'Friend request not found';
      }
      friendShipModel friendship = friendShipModel.fromMap(
        friendshipDoc.data() as Map<String, dynamic>,
        friendshipDoc.id,
      );
      if (friendship.receiverId != currentUser) {
        return 'Bạn không có quyền chấp nhận lời mời này';
      }

      // Kiểm tra status
      if (friendship.status != 'pending') {
        return 'Lời mời đã được xử lý trước đó';
      }
      // Cập nhật trạng thái thành 'accepted'
      await _firestore.collection('friendships').doc(requestId).update({
        'status': 'accepted',
        'updatedAt': DateTime.now(),
      });
      // Update sender's friends list
      DocumentReference senderRef = _firestore.collection('users').doc(friendship.senderId);
      await senderRef.update({
        'friends': FieldValue.arrayUnion([friendship.receiverId]),
        'friendCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      // Update receiver's friends list
      DocumentReference receiverRef = _firestore.collection('users').doc(friendship.receiverId);
      await receiverRef.update({
        'friends': FieldValue.arrayUnion([friendship.senderId]),
        'friendCount': FieldValue.increment(1),
        'updatedAt': DateTime.now(),
      });
      return 'success';
    } catch (e) {
      print('Error accepting friend request: $e');
      return 'An error occurred while accepting the friend request.';
    }
  }

  // Decline friend request
  static Future<String> declineFriendRequest(String friendshipId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'Bạn chưa đăng nhập';
      }

      DocumentSnapshot friendshipDoc = await _firestore.collection('friendships').doc(friendshipId).get();

      if (!friendshipDoc.exists) {
        return 'Lời mời không tồn tại';
      }

      friendShipModel friendship = friendShipModel.fromMap(
        friendshipDoc.data() as Map<String, dynamic>,
        friendshipDoc.id,
      );

      if (friendship.receiverId != currentUser.uid) {
        return 'Bạn không có quyền từ chối lời mời này';
      }

      if (friendship.status != 'pending') {
        return 'Lời mời đã được xử lý trước đó';
      }
      await _firestore.collection('friendships').doc(friendshipId).update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return 'success';
    } catch (e) {
      print('Error declining friend request: $e');
      return 'Có lỗi xảy ra khi từ chối lời mời';
    }
  }

  // LẤY DANH SÁCH LỜI MỜI ĐANG CHỜ
  //Query friendships where receiverId = currentUser.uid AND status = 'pending'
  // Join với users collection để lấy thông tin sender
  // @return List<Map>: Danh sách lời mời kèm thông tin người gửi
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      // Lấy danh sách friendship pending
      QuerySnapshot friendshipSnapshot = await _firestore
          .collection('friendships')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> pendingRequests = [];

      //  Lấy thông tin chi tiết của từng sender
      for (QueryDocumentSnapshot doc in friendshipSnapshot.docs) {
        friendShipModel friendship = friendShipModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id
        );

        // Lấy thông tin sender
        DocumentSnapshot senderDoc = await _firestore
            .collection('users')
            .doc(friendship.senderId)
            .get();

        if (senderDoc.exists) {
          UserModel sender = UserModel.fromMap(
              senderDoc.data() as Map<String, dynamic>,
              senderDoc.id
          );
          pendingRequests.add({
            'friendship': friendship,
            'sender': sender,
            'id': doc.id, // Thêm ID để có thể accept/decline
          });
        }
      }

      return pendingRequests;
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  // GET USER BY ID - Lấy thông tin user theo ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(
          userDoc.data() as Map<String, dynamic>,
          userDoc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // GET FRIENDSHIP STATUS - Kiểm tra trạng thái kết bạn
  static Future<String> getFriendshipStatus(String otherUserId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'none';
      }

      String currentUserId = currentUser.uid;

      // Kiểm tra friendship từ current user -> other user
      QuerySnapshot sentRequest = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();

      // Kiểm tra friendship từ other user -> current user
      QuerySnapshot receivedRequest = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      if (sentRequest.docs.isNotEmpty) {
        friendShipModel friendship = friendShipModel.fromMap(
          sentRequest.docs.first.data() as Map<String, dynamic>,
          sentRequest.docs.first.id,
        );

        if (friendship.status == 'accepted') {
          return 'friends';
        } else if (friendship.status == 'pending') {
          return 'sent'; // Đã gửi lời mời
        }
      }

      if (receivedRequest.docs.isNotEmpty) {
        friendShipModel friendship = friendShipModel.fromMap(
          receivedRequest.docs.first.data() as Map<String, dynamic>,
          receivedRequest.docs.first.id,
        );

        if (friendship.status == 'accepted') {
          return 'friends';
        } else if (friendship.status == 'pending') {
          return 'pending'; // Nhận được lời mời
        }
      }

      return 'none';
    } catch (e) {
      print('Error checking friendship status: $e');
      return 'none';
    }
  }

  // GET USER POSTS - Lấy bài viết của user
  static Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      QuerySnapshot postsSnapshot = await _firestore
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20) // Giới hạn 20 bài gần nhất
          .get();

      List<PostModel> posts = [];
      for (QueryDocumentSnapshot doc in postsSnapshot.docs) {
        try {
          PostModel post = PostModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
          posts.add(post);
        } catch (e) {
          print('Error parsing post ${doc.id}: $e');
        }
      }

      return posts;
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }

  // CANCEL FRIEND REQUEST - Hủy lời mời kết bạn đã gửi
  static Future<String> cancelFriendRequest(String receiverId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'User not logged in';
      }

      String senderId = currentUser.uid;

      QuerySnapshot friendshipQuery = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (friendshipQuery.docs.isEmpty) {
        return 'Không tìm thấy lời mời để hủy';
      }

      // Xóa lời mời
      await _firestore
          .collection('friendships')
          .doc(friendshipQuery.docs.first.id)
          .delete();

      return 'success';
    } catch (e) {
      print('Error canceling friend request: $e');
      return 'Có lỗi xảy ra khi hủy lời mời';
    }
  }

  // UNFRIEND - Hủy kết bạn
  Future<void> unfriend(String friendId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      String currentUserId = currentUser.uid;

      // Tìm friendship document
      QuerySnapshot friendshipQuery1 = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: friendId)
          .where('status', isEqualTo: 'accepted')
          .get();

      QuerySnapshot friendshipQuery2 = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: friendId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      String? friendshipDocId;
      if (friendshipQuery1.docs.isNotEmpty) {
        friendshipDocId = friendshipQuery1.docs.first.id;
      } else if (friendshipQuery2.docs.isNotEmpty) {
        friendshipDocId = friendshipQuery2.docs.first.id;
      }

      if (friendshipDocId == null) {
        throw Exception('Không tìm thấy mối quan hệ bạn bè');
      }

      // Xóa friendship document
      await _firestore.collection('friendships').doc(friendshipDocId).delete();

      // Cập nhật danh sách bạn bè của current user
      await _firestore.collection('users').doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
        'friendCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });

      // Cập nhật danh sách bạn bè của friend
      await _firestore.collection('users').doc(friendId).update({
        'friends': FieldValue.arrayRemove([currentUserId]),
        'friendCount': FieldValue.increment(-1),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error unfriending: $e');
      throw Exception('Có lỗi xảy ra khi hủy kết bạn: ${e.toString()}');
    }
  }

  // GET FRIENDS LIST - Lấy danh sách bạn bè
  Future<List<UserModel>> getFriends() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      String currentUserId = currentUser.uid;

      // Lấy thông tin user hiện tại để có danh sách bạn bè
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) {
        return [];
      }

      UserModel user = UserModel.fromMap(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );

      List<String> friendIds = user.friends;
      List<UserModel> friends = [];

      // Lấy thông tin chi tiết của từng bạn bè
      for (String friendId in friendIds) {
        try {
          DocumentSnapshot friendDoc = await _firestore
              .collection('users')
              .doc(friendId)
              .get();

          if (friendDoc.exists) {
            UserModel friend = UserModel.fromMap(
              friendDoc.data() as Map<String, dynamic>,
              friendDoc.id,
            );
            friends.add(friend);
          }
        } catch (e) {
          print('Error loading friend $friendId: $e');
        }
      }

      return friends;
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  // ACCEPT FRIEND REQUEST với friendshipId
  static Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      String result = await AcceptFriendRequest(friendshipId);
      if (result != 'success') {
        throw Exception(result);
      }
    } catch (e) {
      throw Exception('Có lỗi xảy ra khi chấp nhận lời mời: ${e.toString()}');
    }
  }

  // ACCEPT FRIEND REQUEST với userId (cho profile screen)
  static Future<void> acceptFriendRequestFromUser(String senderId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      String receiverId = currentUser.uid;

      QuerySnapshot friendshipQuery = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (friendshipQuery.docs.isEmpty) {
        throw Exception('Không tìm thấy lời mời kết bạn');
      }

      String friendshipId = friendshipQuery.docs.first.id;
      await acceptFriendRequest(friendshipId);
    } catch (e) {
      throw Exception('Có lỗi xảy ra khi chấp nhận lời mời: ${e.toString()}');
    }
  }
}

