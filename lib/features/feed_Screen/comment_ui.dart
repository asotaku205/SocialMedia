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
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Comment.Delete comment'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Comment.Are you sure you want to delete this comment?'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('General.Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('General.Delete'.tr(), style: const TextStyle(color: Colors.red)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: false,
        title: Text(
          "Feed.Comment".tr(),
          style: const TextStyle(
            color: Colors.white,
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
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: Colors.blueAccent),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            '${'General.Error'.tr()}: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Divider(color: Colors.grey),

                        // ================== DANH SÁCH COMMENT ==================
                        if (comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Comment.No comments yet'.tr(),
                                style: TextStyle(
                                  color: Colors.grey[400],
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
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Color(0xFF262626), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  // Avatar người dùng hiện tại
                  ImageUtils.buildAvatar(
                    imageUrl: AuthService.currentUser?.photoURL,
                    radius: 16,
                    child: AuthService.currentUser?.photoURL == null || 
                           AuthService.currentUser!.photoURL!.isEmpty
                        ? Text(
                            AuthService.currentUser?.displayName?.isNotEmpty == true
                                ? AuthService.currentUser!.displayName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Thay đổi từ Colors.grey sang Colors.black
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Ô nhập comment
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Feed.Comment hint".tr(),
                          hintStyle: const TextStyle(color: Colors.grey),
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.blueAccent),
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
              child: comment.authorAvatar.isEmpty
                  ? Text(
                      comment.authorName.isNotEmpty
                          ? comment.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Thay đổi từ Colors.grey sang Colors.black
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Nội dung comment
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262626), width: 0.5),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
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
                          color: Colors.grey[600],
                        ),
                      ),
                      // Menu xóa comment (chỉ hiện cho tác giả comment hoặc tác giả bài viết)
                      if (isMyComment || isPostAuthor)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          color: const Color(0xFF1A1A1A),
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
                                  const Icon(Icons.delete, color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'General.Delete'.tr(),
                                    style: const TextStyle(color: Colors.white),
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
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
