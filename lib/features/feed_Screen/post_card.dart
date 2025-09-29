import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/services/post_services.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../profile/main_profile.dart';
import 'comment_ui.dart';
import 'package:readmore/readmore.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  bool isBookmarked = false; // Cờ lưu trạng thái bookmark post

  // Controller để điều khiển animation khi bấm "like"
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation controller cho hiệu ứng "tim to ra rồi nhỏ lại"
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  /// Hiện bottom sheet khi bấm vào dấu "3 chấm"
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo nhỏ ở trên
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Nút save/unsave
            _buildOptionItem(
              icon: BoxIcons.bx_bookmark,
              title: isBookmarked ? 'Unsave' : 'Save Post',
              onTap: () {
                setState(() {
                  isBookmarked = !isBookmarked;
                });
                Navigator.pop(context);
              },
            ),
            // Nút copy link
            _buildOptionItem(
              icon: BoxIcons.bx_link,
              title: 'Copy Link',
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget cho từng item trong bottom sheet
  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// StreamBuilder lắng nghe dữ liệu post từ Firestore
  Widget buidListPost() {
    return StreamBuilder(
      stream: PostService.getPostsStream(), // lấy stream post
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // đang load
        }
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error, size: 40)); // có lỗi
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No posts yet")); // không có post
        }

        final posts = snapshot.data!;
        // Duyệt danh sách post và build UI cho từng cái
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return buidUiPost(post);
          },
        );
      },
    );
  }

  /// UI cho từng post
  Widget buidUiPost(PostModel post) {
    final time = timeago.format(post.createdAt); // thời gian đăng dạng "2h ago"

    // Lấy uid của user hiện tại
    final String? currentUserId = AuthService.currentUser?.uid;

    // Lấy thông tin like/comment từ post
    int likeCount = post.likes;
    int commentCount = post.comments;
    bool isLiked = currentUserId != null && post.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Color(0xFF262626), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Header ----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar + Tên + Thời gian
                GestureDetector(
                  onTap: () {
                    // Điều hướng sang trang profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainProfile(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.authorAvatar.isNotEmpty
                            ? NetworkImage(post.authorAvatar)
                            : null,
                        child: post.authorAvatar.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút 3 chấm
                GestureDetector(
                  onTap: _showMoreOptions,
                  child: const Icon(Icons.more_horiz, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- Nội dung bài viết ----------------
            ReadMoreText(
              post.content,
              trimLines: 6,
              trimMode: TrimMode.Line,
              trimCollapsedText: " More",
              trimExpandedText: "  Hide",
              moreStyle: const TextStyle(color: Colors.grey, fontSize: 15),
              lessStyle: const TextStyle(color: Colors.grey, fontSize: 15),
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.start,
            ),

            const SizedBox(height: 12),

            // ---------------- Ảnh trong post ----------------
            if (post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 12),

            // ---------------- Số like + comment ----------------
            Row(
              children: [
                Text(
                  '$likeCount Like',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                // Bấm vào comment count để mở màn comment
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommentUi(),
                      ),
                    );
                  },
                  child: Text(
                    '$commentCount Comment',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ---------------- Hàng nút Like / Comment / Share / Bookmark ----------------
            Row(
              children: [
                // LIKE BUTTON 
                GestureDetector(
                  onTap: () async {
                    final uid = AuthService.currentUser?.uid;
                    if (uid == null) {
                      // Nếu chưa login thì báo lỗi
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn cần đăng nhập để thực hiện thao tác này.'),
                        ),
                      );
                      return;
                    }

                    // Play animation ngay khi bấm (cho cảm giác mượt)
                    _likeAnimationController.forward().then((_) {
                      _likeAnimationController.reverse();
                    });

                    // Gọi service để toggle like trên Firestore
                    await PostService.toggleLike(post.id, uid);
                    // UI sẽ tự update nhờ stream
                  },
                  child: AnimatedBuilder(
                    animation: _likeAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _likeAnimation.value,
                        child: Icon(
                          isLiked ? BoxIcons.bxs_heart : BoxIcons.bx_heart,
                          color: isLiked ? Colors.red : Colors.grey[400],
                          size: 22,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 16),

                // COMMENT BUTTON 
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommentUi(),
                      ),
                    );
                  },
                  child: Icon(
                    BoxIcons.bx_message_rounded,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                // SHARE BUTTON 
                Icon(BoxIcons.bx_send, color: Colors.grey[400], size: 22),

                const Spacer(),

                // BOOKMARK BUTTON 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isBookmarked = !isBookmarked;
                    });
                  },
                  child: Icon(
                    isBookmarked ? BoxIcons.bxs_bookmark : BoxIcons.bx_bookmark,
                    color: isBookmarked ? Colors.yellow : Colors.grey[400],
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build list post từ stream
    return buidListPost();
  }
}
