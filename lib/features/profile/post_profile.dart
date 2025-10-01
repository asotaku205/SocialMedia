import 'package:blogapp/features/feed_Screen/comment_ui.dart';
import 'package:blogapp/models/post_model.dart';
import 'package:blogapp/services/auth_service.dart';
import 'package:blogapp/services/post_services.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:readmore/readmore.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../resource/navigation.dart';

class PostProfile extends StatefulWidget {
  final String? userId;

  const PostProfile({super.key, this.userId});

  @override
  State<PostProfile> createState() => _PostProfileState();
}

class _PostProfileState extends State<PostProfile> with TickerProviderStateMixin {
  bool isBookmarked = false; // Cờ bookmark (global cho demo)
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  // Build toàn bộ list post từ stream
  Widget buildListPost() {
    final String? targetUserId = widget.userId ?? AuthService.currentUser?.uid; // lấy uid tại thời điểm render
    return StreamBuilder<List<PostModel>>(
      stream: PostService.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error, size: 40));
        }
        final allPosts = snapshot.data ?? [];

        // Lọc posts của user hiện tại trước khi build ListView
        final userPosts = targetUserId == null
            ? <PostModel>[] //neu user null tra ve list rong
            : allPosts.where((p) => p.authorId == targetUserId).toList();
        //tim tat ca user co id = authorId bai viet
        if (userPosts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No posts yet", style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: userPosts.length,
          itemBuilder: (context, index) {
            final post = userPosts[index];
            return buildUiPost(post);
          },
        );
      },
    );
  }

  // UI cho từng post
  Widget buildUiPost(PostModel post) {
    final time = timeago.format(post.createdAt);
    final String? currentUserId = AuthService.currentUser?.uid;
    final int likeCount = post.likes;
    final int commentCount = post.comments;
    final bool isLiked = currentUserId != null && post.likedBy.contains(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Color(0xFF262626), width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => NavigationUtils.navigateToProfile(context, post.authorId),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: post.authorAvatar.isNotEmpty ? NetworkImage(post.authorAvatar) : null,
                        child: post.authorAvatar.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          Text(time, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // show options (save/copy link)
                    _showMoreOptions(post);
                  },
                  child: const Icon(Icons.more_horiz, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CommentUi(post: post)));
              },
              child: ReadMoreText(
                post.content,
                trimLines: 6,
                trimMode: TrimMode.Line,
                trimCollapsedText: " More",
                trimExpandedText: "  Hide",
                moreStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                lessStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            // Image (nếu có) với errorBuilder
            if (post.imageUrls.isNotEmpty && post.imageUrls.first.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls.first,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.3,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    color: Colors.grey[900],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.white70),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // Like & Comment counts
            Row(
              children: [
                Text(
                  '$likeCount Like',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CommentUi(post: post)));
                  },
                  child: Text(
                    '$commentCount Comment',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final uid = AuthService.currentUser?.uid;
                    if (uid == null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Bạn cần đăng nhập để thực hiện thao tác này.')));
                      return;
                    }
                    _likeAnimationController.forward().then((_) {
                      _likeAnimationController.reverse();
                    });
                    await PostService.toggleLike(post.id, uid);
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

                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CommentUi(post: post)));
                  },
                  child: Icon(BoxIcons.bx_message_rounded, color: Colors.grey[400], size: 22),
                ),

                const SizedBox(width: 16),

                Icon(BoxIcons.bx_send, color: Colors.grey[400], size: 22),

                const Spacer(),

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

  void _showMoreOptions(PostModel post) {
    final String? currentUserId = AuthService.currentUser?.uid;
    final bool isOwner = currentUserId != null && currentUserId == post.authorId;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  isBookmarked = !isBookmarked;
                });
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(BoxIcons.bx_bookmark, color: Colors.white, size: 22),
                    const SizedBox(width: 16),
                    const Text(
                      'Save Post',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Icon(BoxIcons.bx_link, color: Colors.white, size: 22),
                    const SizedBox(width: 16),
                    const Text(
                      'Copy Link',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            // Chỉ hiển thị nút Delete nếu là chủ bài viết
            if (isOwner)
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final delPost = await PostService.deletePost(post.id);
                    if (delPost == "success") {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete success")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error deleting post")));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Icon(BoxIcons.bx_trash, color: Colors.red, size: 22),
                      const SizedBox(width: 16),
                      const Text(
                        'Delete',
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

  @override
  Widget build(BuildContext context) {
    return buildListPost();
  }
}
