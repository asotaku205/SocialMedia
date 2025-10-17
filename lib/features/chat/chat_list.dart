import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'chat_detail.dart';
import 'package:blogapp/services/chat_service.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/image_utils.dart';

class ChatList extends StatefulWidget {
  final UserModel friend;
  final VoidCallback? onChatUpdate; // Thêm callback

  const ChatList({super.key, required this.friend, this.onChatUpdate});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Hôm nay - hiển thị giờ:phút
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      // Hôm qua
      return 'Chat.Yesterday'.tr();
    } else {
      // Ngày khác - hiển thị ngày/tháng
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<MessageModel>>(
      stream: ChatService.getMessages(widget.friend.uid),
      builder: (context, messageSnapshot) {
        // Đếm số tin nhắn chưa đọc
        int unreadCount = 0;
        if (messageSnapshot.hasData) {
          unreadCount = messageSnapshot.data!
              .where((msg) => 
                msg.receiverId == currentUserId && 
                !msg.isRead)
              .length;
        }

        final hasUnread = unreadCount > 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatDetail(
                otherUserId: widget.friend.uid,
                otherUserName: widget.friend.displayName.isNotEmpty
                    ? widget.friend.displayName
                    : widget.friend.userName,
                otherUserAvatar: widget.friend.photoURL,
                onMessageSent: widget.onChatUpdate, // Truyền callback
              )),
            );
          },
          child: Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: hasUnread 
                  ? colorScheme.primary.withOpacity(0.08)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: hasUnread 
                      ? colorScheme.primary 
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 2),
                      ),
                      child: ImageUtils.buildAvatar(
                        imageUrl: widget.friend.photoURL,
                        radius: 28,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        child: widget.friend.photoURL.isEmpty
                            ? Text(
                                widget.friend.displayName.isNotEmpty
                                    ? widget.friend.displayName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                ),
                              )
                            : null,
                        context: context,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.friend.displayName.isNotEmpty
                                  ? widget.friend.displayName
                                  : widget.friend.userName,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 6),
                            StreamBuilder<List<MessageModel>>(
                              stream: ChatService.getMessages(widget.friend.uid),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Text(
                                    'Chat.No messages yet'.tr(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      fontWeight: FontWeight.bold
                                    ),
                                  );
                                }

                                final latestMessage = snapshot.data!.first;
                                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                final isMe = latestMessage.senderId == currentUserId;

                                return Text(
                                  isMe ? '${'Chat.You'.tr()} ${latestMessage.content}' : latestMessage.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: hasUnread 
                                        ? colorScheme.onSurface 
                                        : colorScheme.onSurface.withOpacity(0.6),
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StreamBuilder<List<MessageModel>>(
                    stream: ChatService.getMessages(widget.friend.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return SizedBox.shrink();
                      }

                      final latestMessage = snapshot.data!.first;
                      return Text(
                        _formatTime(latestMessage.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                          color: hasUnread 
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                  if (hasUnread) ...[
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
      },
    );
  }
}
