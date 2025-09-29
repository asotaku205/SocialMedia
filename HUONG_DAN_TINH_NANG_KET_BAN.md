# HƯỚNG DẪN CHI TIẾT TÍNH NĂNG KẾT BẠN

## 1. PHÂN TÍCH TỔNG QUAN

### 1.1 Các chức năng cần có:
- Gửi lời mời kết bạn (Send Friend Request)
- Chấp nhận/Từ chối lời mời (Accept/Decline Request)
- Hiển thị danh sách bạn bè (Friends List)
- Hiển thị lời mời đang chờ (Pending Requests)
- Hủy kết bạn (Unfriend)
- Kiểm tra trạng thái kết bạn (Check Friendship Status)

### 1.2 Database Structure:

#### Collection `friendships`:
```dart
{
  'id': 'auto_generated_id',
  'senderId': 'uid_của_người_gửi_lời_mời',
  'receiverId': 'uid_của_người_nhận_lời_mời',
  'status': 'pending' | 'accepted' | 'declined',
  'createdAt': Timestamp,
  'updatedAt': Timestamp
}
```

#### Cập nhật UserModel:
```dart
class UserModel {
  // ...existing fields...
  List<String> friends;     // Danh sách UID của bạn bè
  int friendCount;          // Số lượng bạn bè (để hiển thị nhanh)
}
```

---

## 2. BƯỚC 1: TẠO FRIENDSHIP MODEL

### File: `lib/models/friendship_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendshipModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendshipModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert object thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Tạo object từ Firestore data
  factory FriendshipModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FriendshipModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Copy object với một số field được thay đổi
  FriendshipModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

## 3. BƯỚC 2: TẠO FRIENDSHIP SERVICE

### File: `lib/services/friendship_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';
import './auth_service.dart';

class FriendshipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. GỬI LỜI MỜI KẾT BẠN
  /// 
  /// Logic:
  /// - Kiểm tra user đã đăng nhập chưa
  /// - Kiểm tra không tự gửi cho mình
  /// - Kiểm tra đã có friendship chưa (tránh duplicate)
  /// - Tạo document mới trong collection 'friendships'
  /// 
  /// @param receiverId: UID của người nhận lời mời
  /// @return String: 'success' nếu thành công, error message nếu thất bại
  static Future<String> sendFriendRequest(String receiverId) async {
    try {
      // 1. Kiểm tra user đã đăng nhập
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'Bạn chưa đăng nhập';
      }

      String senderId = currentUser.uid;

      // 2. Kiểm tra không gửi cho chính mình
      if (senderId == receiverId) {
        return 'Không thể kết bạn với chính mình';
      }

      // 3. Kiểm tra đã có friendship chưa
      QuerySnapshot existingFriendship = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .get();

      // Kiểm tra friendship ngược lại (người kia đã gửi cho mình chưa)
      QuerySnapshot reverseFriendship = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: senderId)
          .get();

      if (existingFriendship.docs.isNotEmpty) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          existingFriendship.docs.first.data() as Map<String, dynamic>,
          existingFriendship.docs.first.id
        );
        
        if (friendship.status == 'pending') {
          return 'Lời mời đã được gửi trước đó';
        } else if (friendship.status == 'accepted') {
          return 'Hai bạn đã là bạn bè';
        }
      }

      if (reverseFriendship.docs.isNotEmpty) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          reverseFriendship.docs.first.data() as Map<String, dynamic>,
          reverseFriendship.docs.first.id
        );
        
        if (friendship.status == 'pending') {
          return 'Người này đã gửi lời mời cho bạn, hãy kiểm tra danh sách lời mời';
        } else if (friendship.status == 'accepted') {
          return 'Hai bạn đã là bạn bè';
        }
      }

      // 4. Tạo friendship mới
      FriendshipModel newFriendship = FriendshipModel(
        id: '', // Firestore sẽ tự tạo
        senderId: senderId,
        receiverId: receiverId,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('friendships').add(newFriendship.toMap());
      return 'success';

    } catch (e) {
      print('Error sending friend request: $e');
      return 'Có lỗi xảy ra khi gửi lời mời';
    }
  }

  /// 2. CHẤP NHẬN LỜI MỜI KẾT BẠN
  /// 
  /// Logic:
  /// - Tìm friendship document bằng ID
  /// - Kiểm tra quyền (chỉ người nhận mới được accept)
  /// - Update status thành 'accepted'
  /// - Thêm UID vào friends array của cả 2 user
  /// - Tăng friendCount của cả 2 user
  /// 
  /// @param friendshipId: ID của document friendship
  /// @return String: 'success' nếu thành công, error message nếu thất bại
  static Future<String> acceptFriendRequest(String friendshipId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'Bạn chưa đăng nhập';
      }

      // 1. Lấy friendship document
      DocumentSnapshot friendshipDoc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (!friendshipDoc.exists) {
        return 'Lời mời không tồn tại';
      }

      FriendshipModel friendship = FriendshipModel.fromMap(
        friendshipDoc.data() as Map<String, dynamic>,
        friendshipDoc.id
      );

      // 2. Kiểm tra quyền (chỉ người nhận mới được accept)
      if (friendship.receiverId != currentUser.uid) {
        return 'Bạn không có quyền chấp nhận lời mời này';
      }

      // 3. Kiểm tra status
      if (friendship.status != 'pending') {
        return 'Lời mời đã được xử lý trước đó';
      }

      // 4. Sử dụng batch để đảm bảo tất cả thao tác thành công
      WriteBatch batch = _firestore.batch();

      // Update friendship status
      DocumentReference friendshipRef = _firestore
          .collection('friendships')
          .doc(friendshipId);
      
      batch.update(friendshipRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update sender's friends list
      DocumentReference senderRef = _firestore
          .collection('users')
          .doc(friendship.senderId);
      
      batch.update(senderRef, {
        'friends': FieldValue.arrayUnion([friendship.receiverId]),
        'friendCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update receiver's friends list
      DocumentReference receiverRef = _firestore
          .collection('users')
          .doc(friendship.receiverId);
      
      batch.update(receiverRef, {
        'friends': FieldValue.arrayUnion([friendship.senderId]),
        'friendCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Thực thi tất cả thao tác
      await batch.commit();
      return 'success';

    } catch (e) {
      print('Error accepting friend request: $e');
      return 'Có lỗi xảy ra khi chấp nhận lời mời';
    }
  }

  /// 3. TỪ CHỐI LỜI MỜI KẾT BẠN
  /// 
  /// Logic:
  /// - Tìm friendship document
  /// - Kiểm tra quyền
  /// - Update status thành 'declined' HOẶC xóa document
  /// 
  /// @param friendshipId: ID của document friendship
  /// @return String: 'success' nếu thành công, error message nếu thất bại
  static Future<String> declineFriendRequest(String friendshipId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'Bạn chưa đăng nhập';
      }

      DocumentSnapshot friendshipDoc = await _firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (!friendshipDoc.exists) {
        return 'Lời mời không tồn tại';
      }

      FriendshipModel friendship = FriendshipModel.fromMap(
        friendshipDoc.data() as Map<String, dynamic>,
        friendshipDoc.id
      );

      if (friendship.receiverId != currentUser.uid) {
        return 'Bạn không có quyền từ chối lời mời này';
      }

      if (friendship.status != 'pending') {
        return 'Lời mời đã được xử lý trước đó';
      }

      // Có 2 cách: update status hoặc xóa document
      // Cách 1: Update status (giữ lại để tracking)
      await _firestore.collection('friendships').doc(friendshipId).update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cách 2: Xóa luôn document (nếu không cần tracking)
      // await _firestore.collection('friendships').doc(friendshipId).delete();

      return 'success';

    } catch (e) {
      print('Error declining friend request: $e');
      return 'Có lỗi xảy ra khi từ chối lời mời';
    }
  }

  /// 4. LẤY DANH SÁCH LỜI MỜI ĐANG CHỜ
  /// 
  /// Logic:
  /// - Query friendships where receiverId = currentUser.uid AND status = 'pending'
  /// - Join với users collection để lấy thông tin sender
  /// 
  /// @return List<Map>: Danh sách lời mời kèm thông tin người gửi
  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      // 1. Lấy danh sách friendship pending
      QuerySnapshot friendshipSnapshot = await _firestore
          .collection('friendships')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> pendingRequests = [];

      // 2. Lấy thông tin chi tiết của từng sender
      for (QueryDocumentSnapshot doc in friendshipSnapshot.docs) {
        FriendshipModel friendship = FriendshipModel.fromMap(
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
          });
        }
      }

      return pendingRequests;

    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// 5. LẤY DANH SÁCH BẠN BÈ
  /// 
  /// Logic:
  /// - Query friendships where status = 'accepted' AND
  ///   (senderId = currentUser.uid OR receiverId = currentUser.uid)
  /// - Lấy UID của friends
  /// - Query users collection để lấy thông tin chi tiết
  /// 
  /// @return List<UserModel>: Danh sách bạn bè
  static Future<List<UserModel>> getFriendsList() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      String currentUserId = currentUser.uid;

      // 1. Query friendships as sender
      QuerySnapshot sentFriendships = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // 2. Query friendships as receiver
      QuerySnapshot receivedFriendships = await _firestore
          .collection('friendships')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .get();

      // 3. Collect friend UIDs
      Set<String> friendUIDs = {};

      for (QueryDocumentSnapshot doc in sentFriendships.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        friendUIDs.add(data['receiverId']);
      }

      for (QueryDocumentSnapshot doc in receivedFriendships.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        friendUIDs.add(data['senderId']);
      }

      // 4. Get friend details
      List<UserModel> friends = [];

      for (String friendUID in friendUIDs) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(friendUID)
            .get();

        if (userDoc.exists) {
          UserModel friend = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
            userDoc.id
          );
          friends.add(friend);
        }
      }

      // 5. Sort by name
      friends.sort((a, b) => a.displayName.compareTo(b.displayName));

      return friends;

    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }

  /// 6. HỦY KẾT BẠN
  /// 
  /// Logic:
  /// - Tìm friendship document giữa 2 user
  /// - Xóa document hoặc update status
  /// - Remove UID khỏi friends array của cả 2 user
  /// - Giảm friendCount của cả 2 user
  /// 
  /// @param friendId: UID của bạn muốn hủy kết bạn
  /// @return String: 'success' nếu thành công, error message nếu thất bại
  static Future<String> unfriend(String friendId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'Bạn chưa đăng nhập';
      }
      String currentUserId = currentUser.uid;

      // 1. Tìm friendship document
      QuerySnapshot friendshipQuery = await _firestore
          .collection('friendships')
          .where('status', isEqualTo: 'accepted')
          .get();

      String? friendshipId;
      for (QueryDocumentSnapshot doc in friendshipQuery.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if ((data['senderId'] == currentUserId && data['receiverId'] == friendId) ||
            (data['senderId'] == friendId && data['receiverId'] == currentUserId)) {
          friendshipId = doc.id;
          break;
        }
      }

      if (friendshipId == null) {
        return 'Hai bạn không phải là bạn bè';
      }

      // 2. Sử dụng batch để đảm bảo tất cả thao tác thành công
      WriteBatch batch = _firestore.batch();

      // Xóa friendship document
      DocumentReference friendshipRef = _firestore
          .collection('friendships')
          .doc(friendshipId);
      batch.delete(friendshipRef);

      // Update current user's friends list
      DocumentReference currentUserRef = _firestore
          .collection('users')
          .doc(currentUserId);
      batch.update(currentUserRef, {
        'friends': FieldValue.arrayRemove([friendId]),
        'friendCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update friend's friends list
      DocumentReference friendRef = _firestore
          .collection('users')
          .doc(friendId);
      batch.update(friendRef, {
        'friends': FieldValue.arrayRemove([currentUserId]),
        'friendCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return 'success';

    } catch (e) {
      print('Error unfriending: $e');
      return 'Có lỗi xảy ra khi hủy kết bạn';
    }
  }

  /// 7. KIỂM TRA TRẠNG THÁI KẾT BẠN
  /// 
  /// Logic:
  /// - Query friendship giữa 2 user
  /// - Trả về status: 'none', 'pending_sent', 'pending_received', 'friends'
  /// 
  /// @param otherUserId: UID của user khác
  /// @return String: Trạng thái kết bạn
  static Future<String> getFriendshipStatus(String otherUserId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'not_logged_in';
      }

      String currentUserId = currentUser.uid;

      if (currentUserId == otherUserId) {
        return 'self';
      }

      // Query friendship as sender
      QuerySnapshot sentQuery = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();

      if (sentQuery.docs.isNotEmpty) {
        String status = sentQuery.docs.first['status'];
        if (status == 'accepted') return 'friends';
        if (status == 'pending') return 'pending_sent';
      }

      // Query friendship as receiver
      QuerySnapshot receivedQuery = await _firestore
          .collection('friendships')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .get();

      if (receivedQuery.docs.isNotEmpty) {
        String status = receivedQuery.docs.first['status'];
        if (status == 'accepted') return 'friends';
        if (status == 'pending') return 'pending_received';
      }

      return 'none';

    } catch (e) {
      print('Error getting friendship status: $e');
      return 'error';
    }
  }

  /// 8. STREAM CHO REAL-TIME UPDATES
  /// 
  /// Stream để lắng nghe thay đổi danh sách bạn bè real-time
  static Stream<List<UserModel>> getFriendsStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) return <UserModel>[];

      List<String> friendIds = List<String>.from(userDoc['friends'] ?? []);
      if (friendIds.isEmpty) return <UserModel>[];

      List<UserModel> friends = [];
      for (String friendId in friendIds) {
        DocumentSnapshot friendDoc = await _firestore
            .collection('users')
            .doc(friendId)
            .get();
        
        if (friendDoc.exists) {
          friends.add(UserModel.fromMap(
            friendDoc.data() as Map<String, dynamic>,
            friendDoc.id
          ));
        }
      }

      return friends;
    });
  }
}
```

---

## 4. BƯỚC 3: CẬP NHẬT USER MODEL

### Cập nhật file: `lib/models/user_model.dart`

Thêm 2 fields mới vào UserModel:

```dart
class UserModel {
  // ...existing fields...
  final List<String> friends;
  final int friendCount;

  UserModel({
    // ...existing parameters...
    this.friends = const [],
    this.friendCount = 0,
  });

  // Cập nhật toMap() method
  Map<String, dynamic> toMap() {
    return {
      // ...existing fields...
      'friends': friends,
      'friendCount': friendCount,
    };
  }

  // Cập nhật fromMap() factory
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      // ...existing fields...
      friends: List<String>.from(map['friends'] ?? []),
      friendCount: map['friendCount'] ?? 0,
    );
  }

  // Cập nhật copyWith() method
  UserModel copyWith({
    // ...existing parameters...
    List<String>? friends,
    int? friendCount,
  }) {
    return UserModel(
      // ...existing fields...
      friends: friends ?? this.friends,
      friendCount: friendCount ?? this.friendCount,
    );
  }
}
```

---

## 5. BƯỚC 4: TẠO UI COMPONENTS

### 5.1 File: `lib/widgets/friend_request_card.dart`

```dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/friendship_model.dart';
import '../services/friendship_service.dart';

class FriendRequestCard extends StatefulWidget {
  final UserModel sender;
  final FriendshipModel friendship;
  final VoidCallback? onActionCompleted;

  const FriendRequestCard({
    Key? key,
    required this.sender,
    required this.friendship,
    this.onActionCompleted,
  }) : super(key: key);

  @override
  State<FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends State<FriendRequestCard> {
  bool isLoading = false;

  Future<void> _acceptRequest() async {
    setState(() => isLoading = true);
    
    String result = await FriendshipService.acceptFriendRequest(widget.friendship.id);
    
    if (mounted) {
      setState(() => isLoading = false);
      
      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chấp nhận lời mời từ ${widget.sender.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onActionCompleted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest() async {
    setState(() => isLoading = true);
    
    String result = await FriendshipService.declineFriendRequest(widget.friendship.id);
    
    if (mounted) {
      setState(() => isLoading = false);
      
      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã từ chối lời mời từ ${widget.sender.displayName}'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onActionCompleted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: widget.sender.photoURL.isNotEmpty
                  ? NetworkImage(widget.sender.photoURL)
                  : const NetworkImage("https://picsum.photos/100/100?random=1"),
            ),
            const SizedBox(width: 12),
            
            // Thông tin user
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sender.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '@${widget.sender.userName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Gửi lời mời ${_formatTime(widget.friendship.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Buttons
            if (isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _acceptRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Chấp nhận'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _declineRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    Duration diff = DateTime.now().difference(time);
    if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
```

### 5.2 File: `lib/widgets/friend_card.dart`

```dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/friendship_service.dart';

class FriendCard extends StatefulWidget {
  final UserModel friend;
  final VoidCallback? onUnfriend;

  const FriendCard({
    Key? key,
    required this.friend,
    this.onUnfriend,
  }) : super(key: key);

  @override
  State<FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<FriendCard> {
  bool isLoading = false;

  Future<void> _showUnfriendDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hủy kết bạn'),
          content: Text('Bạn có chắc muốn hủy kết bạn với ${widget.friend.displayName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hủy kết bạn'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _unfriend();
    }
  }

  Future<void> _unfriend() async {
    setState(() => isLoading = true);
    
    String result = await FriendshipService.unfriend(widget.friend.uid);
    
    if (mounted) {
      setState(() => isLoading = false);
      
      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã hủy kết bạn với ${widget.friend.displayName}'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onUnfriend?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: widget.friend.photoURL.isNotEmpty
              ? NetworkImage(widget.friend.photoURL)
              : const NetworkImage("https://picsum.photos/100/100?random=1"),
        ),
        title: Text(
          widget.friend.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${widget.friend.userName}'),
            if (widget.friend.bio.isNotEmpty)
              Text(
                widget.friend.bio,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'unfriend') {
                    _showUnfriendDialog();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'unfriend',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hủy kết bạn'),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () {
          // Navigate to friend's profile
          // Navigator.push(context, MaterialPageRoute(
          //   builder: (context) => ProfileScreen(user: widget.friend)
          // ));
        },
      ),
    );
  }
}
```

---

## 6. BƯỚC 5: TẠO FRIENDS SCREEN

### File: `lib/features/friends/friends_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/friendship_service.dart';
import '../../models/user_model.dart';
import '../../widgets/friend_card.dart';
import '../../widgets/friend_request_card.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<UserModel> friends = [];
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoadingFriends = false;
  bool isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadFriends(),
      _loadPendingRequests(),
    ]);
  }

  Future<void> _loadFriends() async {
    setState(() => isLoadingFriends = true);
    
    try {
      List<UserModel> loadedFriends = await FriendshipService.getFriendsList();
      if (mounted) {
        setState(() {
          friends = loadedFriends;
          isLoadingFriends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingFriends = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh sách bạn bè: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() => isLoadingRequests = true);
    
    try {
      List<Map<String, dynamic>> loadedRequests = 
          await FriendshipService.getPendingRequests();
      if (mounted) {
        setState(() {
          pendingRequests = loadedRequests;
          isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingRequests = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải lời mời kết bạn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Bạn bè (${friends.length})',
              icon: const Icon(Icons.people),
            ),
            Tab(
              text: 'Lời mời (${pendingRequests.length})',
              icon: const Icon(Icons.person_add),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Danh sách bạn bè
          _buildFriendsTab(),
          // Tab 2: Lời mời kết bạn
          _buildRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    if (isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có bạn bè nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy tìm kiếm và kết bạn với mọi người!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return FriendCard(
            friend: friends[index],
            onUnfriend: _loadFriends, // Reload danh sách sau khi unfriend
          );
        },
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có lời mời nào',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Các lời mời kết bạn sẽ hiển thị ở đây',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        itemCount: pendingRequests.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> request = pendingRequests[index];
          return FriendRequestCard(
            sender: request['sender'],
            friendship: request['friendship'],
            onActionCompleted: _loadData, // Reload cả 2 tab
          );
        },
      ),
    );
  }
}
```

---

## 7. BƯỚC 6: TÍCH HỢP VÀO PROFILE SCREEN

### Cập nhật Profile Screen để hiển thị nút Add Friend:

```dart
// Trong profile_screen.dart, thêm method này:

Future<String> _getFriendshipStatus(String otherUserId) async {
  return await FriendshipService.getFriendshipStatus(otherUserId);
}

Future<void> _sendFriendRequest(String receiverId) async {
  String result = await FriendshipService.sendFriendRequest(receiverId);
  
  if (result == 'success') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi lời mời kết bạn'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {}); // Refresh UI
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Widget để hiển thị nút Friend action
Widget _buildFriendActionButton(String otherUserId) {
  return FutureBuilder<String>(
    future: _getFriendshipStatus(otherUserId),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const CircularProgressIndicator();
      }

      String status = snapshot.data!;
      
      switch (status) {
        case 'friends':
          return ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const FriendsScreen(),
              ));
            },
            icon: const Icon(Icons.people),
            label: const Text('Bạn bè'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          );
          
        case 'pending_sent':
          return OutlinedButton.icon(
            onPressed: null, // Disable button
            icon: const Icon(Icons.access_time),
            label: const Text('Đã gửi lời mời'),
          );
          
        case 'pending_received':
          return ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const FriendsScreen(),
              ));
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Phản hồi lời mời'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          );
          
        case 'none':
          return ElevatedButton.icon(
            onPressed: () => _sendFriendRequest(otherUserId),
            icon: const Icon(Icons.person_add),
            label: const Text('Kết bạn'),
          );
          
        default:
          return const SizedBox.shrink();
      }
    },
  );
}
```

---

## 8. BƯỚC 7: CẬP NHẬT FIRESTORE RULES

### Thêm vào `firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...
    
    // Rules cho collection friendships
    match /friendships/{friendshipId} {
      // Cho phép đọc nếu user là sender hoặc receiver
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
         
      // Cho phép tạo nếu user là sender
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.senderId;
        
      // Cho phép update nếu user là receiver (để accept/decline)
      allow update: if request.auth != null && 
        request.auth.uid == resource.data.receiverId;
        
      // Cho phép delete nếu user là sender hoặc receiver
      allow delete: if request.auth != null && 
        (request.auth.uid == resource.data.senderId || 
         request.auth.uid == resource.data.receiverId);
    }
    
    // Cập nhật rules cho users (cho phép update friends array)
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Cho phép đọc profile của user khác
    }
  }
}
```

---

## 9. BƯỚC 8: TESTING VÀ DEBUG

### 9.1 Các trường hợp cần test:

1. **Gửi lời mời kết bạn:**
   - Gửi thành công
   - Không thể gửi cho chính mình  
   - Không thể gửi duplicate request
   - Xử lý khi người kia đã gửi lời mời trước

2. **Chấp nhận/Từ chối lời mời:**
   - Chấp nhận thành công → cả 2 user có trong friends list
   - Từ chối thành công → friendship status = declined
   - Chỉ receiver mới có thể accept/decline

3. **Hủy kết bạn:**
   - Hủy thành công → remove khỏi friends list của cả 2
   - Update friendCount chính xác

4. **UI Components:**
   - Loading states hoạt động tốt
   - Error handling hiển thị đúng
   - Real-time updates (nếu dùng Stream)

### 9.2 Debug Tips:

```dart
// Thêm debug logs vào các methods:
print('Sending friend request from $senderId to $receiverId');
print('Friendship status: $status');
print('Current user friends: ${currentUser.friends}');
```

---

## 10. TÍNH NĂNG BỔ SUNG (OPTIONAL)

### 10.1 Search Friends:
- Tìm kiếm user theo tên, username
- Filter theo trạng thái kết bạn

### 10.2 Notifications:
- Thông báo khi nhận lời mời mới
- Thông báo khi lời mời được chấp nhận

### 10.3 Mutual Friends:
- Hiển thị bạn chung giữa 2 user

### 10.4 Friend Suggestions:
- Gợi ý kết bạn dựa trên bạn chung

---

## 11. KẾT LUẬN

Với hướng dẫn chi tiết trên, bạn có thể implement đầy đủ tính năng kết bạn cho app của mình. 

**Thứ tự implement khuyến nghị:**
1. Tạo FriendshipModel và cập nhật UserModel
2. Implement FriendshipService từng method một
3. Test từng method qua debug console
4. Tạo UI components 
5. Tích hợp vào các screen hiện có
6. Cập nhật Firestore rules
7. Test tổng thể và fix bugs

**Lưu ý quan trọng:**
- Luôn kiểm tra user authentication trước khi thực hiện thao tác
- Sử dụng batch operations cho các thao tác phức tạp
- Handle errors gracefully với try-catch
- Cung cấp feedback rõ ràng cho user qua SnackBar
- Test kỹ các edge cases

Chúc bạn implement thành công! 🚀
