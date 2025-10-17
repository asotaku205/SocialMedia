import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../utils/image_utils.dart';
import '../feed_Screen/comment_ui.dart';
import '../profile/other_user_profile_screen.dart';
import '../../services/post_services.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        title: Text(
          'Notification.Notifications'.tr(),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.markAllAsRead();
            },
            child: Text('Notification.Mark all read'.tr()),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: colorScheme.secondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Notification.No notifications'.tr(),
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(
                context,
                notification,
                colorScheme,
                textColor,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    ColorScheme colorScheme,
    Color? textColor,
  ) {
    IconData icon;
    Color iconColor;
    String message;

    switch (notification.type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        message = 'Notification.liked your post'.tr();
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        message = 'Notification.commented on your post'.tr();
        break;
      case 'friend_request':
        icon = Icons.person_add;
        iconColor = Colors.green;
        message = 'Notification.sent you a friend request'.tr();
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        message = '';
    }

    return InkWell(
      onTap: () async {
        // Đánh dấu đã đọc
        if (!notification.isRead) {
          await NotificationService.markAsRead(notification.id);
        }

        // Điều hướng dựa vào loại thông báo
        if (notification.type == 'like' || notification.type == 'comment') {
          if (notification.postId != null) {
            // Lấy thông tin post và mở màn hình comment
            final post = await PostService.getPostById(notification.postId!);
            if (post != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CommentUi(post: post)),
              );
            }
          }
        } else if (notification.type == 'friend_request') {
          // Mở profile người gửi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OtherUserProfileScreen(userId: notification.fromUserId),
            ),
          );
        }
      },
      child: Container(
        color: notification.isRead
            ? colorScheme.background
            : colorScheme.primary.withOpacity(0.1),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                ImageUtils.buildAvatar(
                  imageUrl: notification.fromUserAvatar,
                  radius: 24,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  child:
                      notification.fromUserAvatar == null ||
                          notification.fromUserAvatar!.isEmpty
                      ? Text(
                          notification.fromUserName.isNotEmpty
                              ? notification.fromUserName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          ),
                        )
                      : null,
                  context: context,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.background,
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),
            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: textColor, fontSize: 14),
                      children: [
                        TextSpan(
                          text: notification.fromUserName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' $message'),
                      ],
                    ),
                  ),
                  if (notification.content != null &&
                      notification.content!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        notification.content!,
                        style: TextStyle(
                          color: textColor?.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt, locale: 'en'),
                    style: TextStyle(
                      color: colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Dấu chấm chưa đọc
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
