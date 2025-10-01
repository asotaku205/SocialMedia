import 'package:blogapp/features/profile/other_user_profile_screen.dart';
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

  // Pagination variables
  final ScrollController _scrollController = ScrollController();
  List<PostModel> _allPosts = [];
  List<PostModel> _displayedPosts = [];
  static const int _postsPerPage = 10;
  bool _isLoadingMore = false;

  void _navigateToProfile(String postAuthorId) {
    final String? currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == postAuthorId) {
      // Đây là bài viết của chính mình -> vào MainProfile
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MainProfile(),
        ),
      );
    } else {
      // Đây là bài viết của người khác -> vào OtherUserProfileScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(userId: postAuthorId),
        ),
      );
    }
  }

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

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    if (_isLoadingMore || _displayedPosts.length >= _allPosts.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          int currentLength = _displayedPosts.length;
          int newLength = (currentLength + _postsPerPage).clamp(0, _allPosts.length);
          _displayedPosts = _allPosts.take(newLength).toList();
          _isLoadingMore = false;
        });
      }
    });
  }

  void _updatePostsList(List<PostModel> allPosts) {
    _allPosts = allPosts;
    if (_displayedPosts.isEmpty) {
      // First load
      _displayedPosts = _allPosts.take(_postsPerPage).toList();
    } else {
      // Update existing posts but keep pagination
      int currentDisplayCount = _displayedPosts.length;
      _displayedPosts = _allPosts.take(currentDisplayCount).toList();
    }
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

  /// StreamBuilder lắng nghe dữ liệu post từ bạn bè
  Widget buidListPost() {
    return StreamBuilder<List<PostModel>>(
      stream: PostService.getFriendsPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // đang load
        }

        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "Có lỗi xảy ra khi tải bài viết",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild để retry
                  },
                  child: const Text("Thử lại"),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Chưa có bài viết từ bạn bè",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Hãy kết bạn để xem bài viết của họ!",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final posts = snapshot.data!;
        // Cập nhật danh sách bài viết cho pagination
        _updatePostsList(posts);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild để refresh
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _displayedPosts.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _displayedPosts.length) {
                // Hiện loading indicator ở cuối danh sách khi đang load thêm
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final post = _displayedPosts[index];
              return buidUiPost(post);
            },
          ),
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
                  onTap: () => _navigateToProfile(post.authorId),
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
                        builder: (context) => CommentUi(post: post),
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
                        builder: (context) => CommentUi(post: post),
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
