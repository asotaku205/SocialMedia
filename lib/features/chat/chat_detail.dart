import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isSendingImage = false;

  @override
  void initState() {
    super.initState();
    // Đánh dấu tin nhắn đã đọc khi mở chat
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    await ChatService.markMessagesAsRead(widget.otherUserId);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${"Authentication.Error".tr()} $e')),
      );
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
      });

      // Show dialog để nhập caption
      final caption = await showDialog<String>(
        context: context,
        builder: (context) => _ImagePreviewDialog(
          imageFile: image,
          onSend: (captionText) => Navigator.pop(context, captionText),
        ),
      );

      if (caption == null) {
        // User cancelled
        setState(() {
          _selectedImage = null;
        });
        return;
      }

      setState(() {
        _isSendingImage = true;
      });

      await ChatService.sendMessageWithImage(
        widget.otherUserId,
        image,
        caption,
      );

      setState(() {
        _selectedImage = null;
        _isSendingImage = false;
      });

      // Gọi callback nếu có
      widget.onMessageSent?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat.Image sent successfully'.tr())),
        );
      }
    } catch (e) {
      setState(() {
        _selectedImage = null;
        _isSendingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${"Authentication.Error".tr()} $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildMessageInput(ColorScheme colorScheme, Color? textColor) {
    return Container(
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
          // Nút chọn ảnh
          Material(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _isSendingImage ? null : _pickAndSendImage,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.image_outlined,
                  color: _isSendingImage
                      ? colorScheme.secondary.withOpacity(0.5)
                      : colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                  border: OutlineInputBorder(),
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
    );
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
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              child:
                  (widget.otherUserAvatar == null ||
                      widget.otherUserAvatar!.isEmpty)
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
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
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Chat.Online".tr(),
                    style: TextStyle(
                      color: colorScheme.secondary.withOpacity(0.6),
                      fontSize: 12,
                    ),
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
              PopupMenuItem(
                value: 'view_profile',
                child: Text('Friend.View Profile'.tr()),
              ),
              PopupMenuItem(value: 'media', child: Text('Chat.Media'.tr())),
              PopupMenuItem(
                value: 'clear_chat',
                child: Text('Chat.Clear Chat'.tr()),
              ),
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
                  return Center(
                    child: CircularProgressIndicator(color: textColor),
                  );
                }

                if (snapshot.hasError) {
                  print('Stream error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Chat.Error loading messages'.tr(),
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 12,
                          ),
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
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chat.No messages yet',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 16,
                          ),
                        ).tr(),
                        SizedBox(height: 8),
                        Text(
                          'Chat.Start Chat',
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 14,
                          ),
                        ).tr(),
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

                    // Kiểm tra nếu là tin nhắn ảnh
                    if (message.messageType == 'image' &&
                        message.metadata != null &&
                        message.metadata!['imageUrl'] != null) {
                      return _buildImageMessage(
                        message,
                        isMe,
                        colorScheme,
                        textColor,
                      );
                    }

                    // Tin nhắn text thông thường
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : textColor,
                                    fontSize: 16,
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(message.timestamp),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        message.isRead
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 16,
                                        color: message.isRead
                                            ? Colors.lightBlueAccent
                                            : Colors.white70,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(colorScheme, textColor),
        ],
      ),
    );
  }

  Widget _buildImageMessage(
    MessageModel message,
    bool isMe,
    ColorScheme colorScheme,
    Color? textColor,
  ) {
    final imageUrl = message.metadata?['imageUrl'] as String?;
    final caption = message.metadata?['caption'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: GestureDetector(
                      onTap: () {
                        // Show full screen image
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              padding: EdgeInsets.all(16),
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 64,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Image.network(
                        imageUrl,
                        width: MediaQuery.of(context).size.width * 0.65,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            child: Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (caption != null && caption.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Text(
                      caption,
                      style: TextStyle(
                        color: isMe ? Colors.white : textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                // Thêm thời gian và trạng thái đã đọc cho tin nhắn ảnh
                if (isMe)
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                        ),
                      ],
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

// Dialog để preview và nhập caption cho ảnh
class _ImagePreviewDialog extends StatefulWidget {
  final XFile imageFile;
  final Function(String) onSend;

  const _ImagePreviewDialog({required this.imageFile, required this.onSend});

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chat.Send Image'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Image preview
            Flexible(
              child: FutureBuilder<String>(
                future: widget.imageFile.readAsBytes().then(
                  (bytes) => 'data:image/jpeg;base64,${base64Encode(bytes)}',
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.network(snapshot.data!, fit: BoxFit.contain);
                  }
                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
            // Caption input
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: 'Chat.Add caption'.tr(),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
            // Send button
            Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send),
                  label: Text('Chat.Send'.tr()),
                  onPressed: () {
                    widget.onSend(_captionController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
