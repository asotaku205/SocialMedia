import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tạo thông báo mới
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String fromUserName,
    String? fromUserAvatar,
    String? postId,
    String? content,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == userId) return;

      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        fromUserId: currentUser.uid,
        fromUserName: fromUserName,
        fromUserAvatar: fromUserAvatar,
        postId: postId,
        content: content,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      print('Lỗi tạo thông báo: $e');
    }
  }

  // Lấy stream thông báo
  static Stream<List<NotificationModel>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .handleError((error) {
            print('Firestore Query Error: $error');
          })
          .map((snapshot) {
            try {
              final notifications = snapshot.docs
                  .map((doc) {
                    try {
                      return NotificationModel.fromMap(doc.data(), doc.id);
                    } catch (e) {
                      print('Error parsing notification ${doc.id}: $e');
                      return null;
                    }
                  })
                  .whereType<NotificationModel>()
                  .toList();

              return notifications;
            } catch (e) {
              print('Error mapping notifications: $e');
              return <NotificationModel>[];
            }
          });
    } catch (e) {
      print('Fatal error in getNotificationsStream: $e');
      return Stream.value([]);
    }
  }

  // Đếm thông báo chưa đọc
  static Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Đánh dấu đã đọc
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Lỗi đánh dấu đã đọc: $e');
    }
  }

  // Đánh dấu tất cả đã đọc
  static Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Lỗi đánh dấu tất cả đã đọc: $e');
    }
  }

  // Xóa thông báo
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Lỗi xóa thông báo: $e');
    }
  }
}
