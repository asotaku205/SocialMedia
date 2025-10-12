import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/message_model.dart';
import '../../services/chat_service.dart';

class ChatDetail extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final VoidCallback? onMessageSent; // Thêm callback

  const ChatDetail({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.onMessageSent, // Thêm vào constructor
  });

  @override
  State<ChatDetail> createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await ChatService.sendMessage(
        '', // chatId will be generated in the service
        widget.otherUserId, // receiverId
        content, // message content
        'text', // messageType
      );

      _messageController.clear();

      // Gọi callback nếu có
      widget.onMessageSent?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${"Authentication.Error".tr()} $e')));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty)
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: (widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty)
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "Chat.Online".tr(),
                    style: TextStyle(color: colorScheme.secondary.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) {
              // Xử lý menu actions
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'view_profile', child: Text('Friend.View Profile'.tr())),
              PopupMenuItem(value: 'media', child: Text('Media')),
              PopupMenuItem(value: 'clear_chat', child: Text('Clear Chat')),
              PopupMenuItem(value: 'block', child: Text('Block')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: ChatService.getMessages(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: textColor));
                }

                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Lỗi tải tin nhắn', style: TextStyle(color: Colors.red, fontSize: 16)),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: colorScheme.secondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message_outlined, size: 64, color: colorScheme.secondary),
                        SizedBox(height: 16),
                        Text('Chat.No messages yet', style: TextStyle(color: colorScheme.secondary, fontSize: 16)).tr(),
                        SizedBox(height: 8),
                        Text('Chat.Start Chat', style: TextStyle(color: colorScheme.secondary, fontSize: 14)).tr(),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;
                print('Loaded ${messages.length} messages'); // Debug log

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser?.uid;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(message.content, style: TextStyle(color: textColor, fontSize: 16)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.secondary.withOpacity(0.7), width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Chat.Type a message".tr(),
                        hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.4)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: Icon(Icons.send, color: textColor, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
