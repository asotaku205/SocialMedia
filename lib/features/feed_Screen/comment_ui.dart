import 'package:blogapp/features/feed_Screen/single_post.dart';
import 'package:flutter/material.dart';
import '../profile/main_profile.dart';
import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/models/comment_model.dart';
import 'package:blogapp/services/comment_service.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:blogapp/utils/timeago_setup.dart';
import 'package:blogapp/utils/image_utils.dart';
import '../../widgets/full_screen_image.dart';

class CommentUi extends StatefulWidget {
  //truyen doi tuong bai viet v day
  final PostModel post; 
  const CommentUi({super.key, required this.post});

  @override
  State<CommentUi> createState() => _CommentUiState();
}

class _CommentUiState extends State<CommentUi> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize timeago locales
    TimeagoSetup.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hàm để thêm comment mới
  Future<void> _addComment() async {
    if (_controller.text.trim().isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String result = await CommentService.createComment(
        postId: widget.post.id,
        content: _controller.text.trim(),
      );

      if (result == 'success') {
        _controller.clear();
        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Comment.Comment posted successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Hiển thị thông báo lỗi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('General.Error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Hàm để xóa comment
  Future<void> _deleteComment(CommentModel comment) async {
    // Hiển thị dialog xác nhận
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyLarge?.color;
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.background,
        title: Text(
          'Comment.Delete comment'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(color: textColor),
        ),
        content: Text(
          'Comment.Are you sure you want to delete this comment?'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor?.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('General.Cancel'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.secondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('General.Delete'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        String result = await CommentService.deleteComment(
          commentId: comment.id,
          postId: widget.post.id,
        );

        if (result == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Comment.Comment deleted successfully'.tr()),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('General.Error'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
  
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        centerTitle: false,
        title: Text(
          "Feed.Comment".tr(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ================= DANH SÁCH CUỘN =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // ================== HIỂN THỊ 1 BÀI VIẾT DUY NHẤT ==================
                SinglePostCard(post: widget.post),

                const SizedBox(height: 20),

                // ================== DANH SÁCH COMMENT REAL-TIME ==================
                StreamBuilder<List<CommentModel>>(
                  stream: CommentService.getCommentsStream(widget.post.id),
                  builder: (context, snapshot) {
                    // Chỉ hiển thị loading khi đang kết nối lần đầu và chưa có data
                    if (snapshot.connectionState == ConnectionState.waiting && 
                        !snapshot.hasData) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '${'General.Error'.tr()}: ${snapshot.error}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    List<CommentModel> comments = snapshot.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================== TIÊU ĐỀ BÌNH LUẬN ==================
                        Text(
                          "${"Feed.Comment".tr()} (${comments.length})",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Divider(color: colorScheme.secondary),

                        // ================== DANH SÁCH COMMENT ==================
                        if (comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Comment.No comments yet'.tr(),
                                style: TextStyle(
                                  color: colorScheme.secondary.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ...comments.map((comment) => _buildCommentItem(comment)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // ================= INPUT COMMENT =================
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.background,
                border: Border(
                  top: BorderSide(color: colorScheme.surface, width: 0.8),
                ),
              ),
              child: Row(
                children: [
            // Avatar người dùng hiện tại
            ImageUtils.buildAvatar(
              imageUrl: AuthService.currentUser?.photoURL ?? '',
              radius: 18,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              child: (AuthService.currentUser?.photoURL ?? '').isEmpty
                  ? Text(
                      (AuthService.currentUser?.displayName?.isNotEmpty ?? false)
                          ? AuthService.currentUser!.displayName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      ),
                    )
                  : null,
              context: context,
            ),
                  const SizedBox(width: 10),

                  // Ô nhập comment
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Feed.Comment hint".tr(),
                          hintStyle: TextStyle(color: colorScheme.secondary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) => _addComment(),
                      ),
                    ),
                  ),

                  // Nút gửi comment
                  IconButton(
                    icon: _isSubmitting 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          )
                        : Icon(Icons.send, color: colorScheme.primary),
                    onPressed: _isSubmitting ? null : _addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget để hiển thị từng comment
  Widget _buildCommentItem(CommentModel comment) {
    final String currentUserId = AuthService.currentUser?.uid ?? '';
    final bool isMyComment = comment.authorId == currentUserId;
    final bool isPostAuthor = widget.post.authorId == currentUserId;

    final colorScheme = Theme.of(context).colorScheme;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar người comment
          GestureDetector(
            onTap: () {
              // TODO: Điều hướng đến profile của người comment
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainProfile()),
              );
            },
            child: ImageUtils.buildAvatar(
              imageUrl: comment.authorAvatar,
              radius: 18,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              child: comment.authorAvatar.isEmpty
                  ? Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                      ),
                    )
                  : null,
              context: context,
            ),
          ),
          const SizedBox(width: 10),

          // Nội dung comment
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.surface, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên người comment và thời gian
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName.isNotEmpty 
                              ? comment.authorName 
                              : 'Unknown User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        TimeagoSetup.formatTime(
                          comment.createdAt, 
                          context.locale.languageCode
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.secondary.withOpacity(0.6),
                        ),
                      ),
                      // Menu xóa comment (chỉ hiện cho tác giả comment hoặc tác giả bài viết)
                      if (isMyComment || isPostAuthor)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: colorScheme.secondary.withOpacity(0.4),
                            size: 16,
                          ),
                          color: colorScheme.surface,
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteComment(comment);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'General.Delete'.tr(),
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Nội dung comment
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
