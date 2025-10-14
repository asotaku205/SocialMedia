import 'package:blogapp/features/feed_Screen/single_post.dart';
import 'package:flutter/material.dart';
import '../profile/main_profile.dart';
import '../profile/other_user_profile_screen.dart';
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
    
    // Thêm listener để rebuild khi text thay đổi (cho nút gửi)
    _controller.addListener(() {
      setState(() {});
    });
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
                  // Ô nhập comment (không có avatar)
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
                        controller: _controller,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Feed.Comment hint".tr(),
                          hintStyle: TextStyle(
                            color: colorScheme.secondary.withOpacity(0.5),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) => _addComment(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nút gửi comment
                  Material(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _isSubmitting ? null : _addComment,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isSubmitting 
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                                ),
                              )
                            : Icon(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar người comment
          GestureDetector(
            onTap: () {
              // Điều hướng đến profile của người comment
              if (comment.authorId == currentUserId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainProfile()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfileScreen(userId: comment.authorId),
                  ),
                );
              }
            },
            child: ImageUtils.buildAvatar(
              imageUrl: comment.authorAvatar,
              radius: 18,
              backgroundColor: isDark ? Colors.white : Colors.black,
              child: comment.authorAvatar.isEmpty
                  ? Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên người comment và thời gian
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Điều hướng đến profile của người comment
                            if (comment.authorId == currentUserId) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MainProfile()),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserProfileScreen(userId: comment.authorId),
                                ),
                              );
                            }
                          },
                          child: Text(
                            comment.authorName.isNotEmpty 
                                ? comment.authorName 
                                : 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
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
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_horiz,
                            color: colorScheme.secondary.withOpacity(0.5),
                            size: 18,
                          ),
                          color: colorScheme.surface,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteComment(comment);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'General.Delete'.tr(),
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Nội dung comment
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: textColor?.withOpacity(0.85),
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
