import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/services/post_services.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../resource/navigation.dart';
import 'comment_ui.dart';
import 'package:readmore/readmore.dart';
import 'package:blogapp/utils/image_utils.dart';
import 'package:blogapp/utils/timeago_setup.dart';
import '../../widgets/full_screen_image.dart';

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
          int newLength = (currentLength + _postsPerPage).clamp(
            0,
            _allPosts.length,
          );
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
  void _showMoreOptions(PostModel post) {
  final String? currentUserId = AuthService.currentUser?.uid;
  final String postAuthorId = post.authorId;
  final bool isOwner = currentUserId != null && currentUserId == postAuthorId;
  final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.background,
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
                color: colorScheme.secondary.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Nút save/unsave
            _buildOptionItem(
              icon: BoxIcons.bx_bookmark,
              title: isBookmarked ? 'Feed.Unsave'.tr() : 'Feed.Save Post'.tr(),
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
              title: 'Feed.Copy Link'.tr(),
              onTap: () => Navigator.pop(context),
            ),
            // Chỉ hiển thị nút Delete nếu là chủ bài viết
            if (isOwner)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final delPost = await PostService.deletePost(post.id);
                    if (delPost == "success") {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Feed.Delete success".tr())));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Feed.Error deleting post".tr())));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${"General.Error".tr()}: $e")));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Icon(BoxIcons.bx_trash, color: Colors.red, size: 22),
                      const SizedBox(width: 16),
                      Text(
                        'Feed.Delete'.tr(),
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : textColor,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : textColor,
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
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)); // đang load
        }

        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text(
                  "Feed.Error loading posts".tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild để retry
                  },
                  child: Text("Feed.Retry".tr()),
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
                Icon(Icons.people_outline, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                SizedBox(height: 16),
                Text(
                  "Feed.No posts from friends".tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Feed.Add friends to see posts".tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
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
  final colorScheme = Theme.of(context).colorScheme;
  final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // Lấy uid của user hiện tại
    final String? currentUserId = AuthService.currentUser?.uid;

    // Lấy thông tin like/comment từ post
    int likeCount = post.likes;
    int commentCount = post.comments;
    bool isLiked =
        currentUserId != null && post.likedBy.contains(currentUserId);

  // Removed duplicate textColor variable
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: colorScheme.background,
        border: Border(
          bottom: BorderSide(color: colorScheme.surface, width: 0.5),
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
                  onTap: () =>
                      NavigationUtils.navigateToProfile(context, post.authorId),
                  child: Row(
                    children: [
                      ImageUtils.buildAvatar(
                        imageUrl: post.authorAvatar,
                        radius: 20,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        child: post.authorAvatar.isEmpty
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                                ),
                              )
                            : null,
                        context: context,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            TimeagoSetup.formatTime(
                              post.createdAt,
                              context.locale.languageCode, // Đa ngôn ngữ theo locale hiện tại
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.secondary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nút 3 chấm
                GestureDetector(
                  onTap: () => _showMoreOptions(post),
                  child: Icon(Icons.more_horiz, color: colorScheme.secondary),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------- Nội dung bài viết ----------------
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentUi(post: post),
                  ),
                );
              },
              child: ReadMoreText(
                post.content,
                trimLines: 6,
                trimMode: TrimMode.Line,
                trimCollapsedText: " ${'Feed.More'.tr()}",
                trimExpandedText: "  ${'Feed.Hide'.tr()}",
                moreStyle: TextStyle(color: colorScheme.secondary, fontSize: 15),
                lessStyle: TextStyle(color: colorScheme.secondary, fontSize: 15),
                style: TextStyle(fontSize: 20, color: textColor),
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(height: 12),
            // ---------------- Ảnh trong post ----------------
            if (post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(
                        imageUrl: post.imageUrls.first,
                        heroTag: 'post_image_${post.id}',
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'post_image_${post.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.imageUrls.first,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.3,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ---------------- Số like + comment ----------------
            Row(
              children: [
                Text(
                  '$likeCount ${'Feed.Like'.tr()}',
                  style: TextStyle(
                    color: colorScheme.secondary.withOpacity(0.4),
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
                    '$commentCount ${'Feed.Comment'.tr()}',
                    style: TextStyle(
                      color: colorScheme.secondary.withOpacity(0.4),
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
                         SnackBar(
                          content: Text(
                            'General.Action required'.tr(),
                          ),
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
                          color: isLiked ? Colors.red : colorScheme.secondary.withOpacity(0.4),
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
                    color: colorScheme.secondary.withOpacity(0.4),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                // SHARE BUTTON
                Icon(BoxIcons.bx_send, color: colorScheme.secondary.withOpacity(0.4), size: 22),

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
                    color: isBookmarked ? Colors.yellow : colorScheme.secondary.withOpacity(0.4),
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
