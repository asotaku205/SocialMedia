import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/message_model.dart';
import '../../services/chat_service.dart';
import '../../utils/image_utils.dart';

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

  @override
  void initState() {
    super.initState();
    // Thêm listener để rebuild khi text thay đổi (cho nút gửi)
    _messageController.addListener(() {
      setState(() {});
    });
  }

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
            ImageUtils.buildAvatar(
              imageUrl: widget.otherUserAvatar,
              radius: 20,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              child: (widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty)
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        fontSize: 16,
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
              PopupMenuItem(value: 'media', child: Text('Chat.Media'.tr())),
              PopupMenuItem(value: 'clear_chat', child: Text('Chat.Clear Chat'.tr())),
              PopupMenuItem(value: 'block', child: Text('Chat.Block'.tr())),
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
                        Text('Chat.Error loading messages'.tr(), style: TextStyle(color: Colors.red, fontSize: 16)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.background,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Chat.Type a message".tr(),
                        hintStyle: TextStyle(
                          color: colorScheme.secondary.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.send_rounded,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
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
